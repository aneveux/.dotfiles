#!/usr/bin/env bash
# Hook contract tests for ~/.claude/hooks and the CC Safety Net rulebook.
#
# SAFETY PRINCIPLE, NON-NEGOTIABLE: test the DETECTORS, never the PAYLOADS.
# Dangerous or secret-shaped strings only ever travel as JSON data on a hook's
# stdin, or as an argument to `cc-safety-net explain`, which analyses a command
# without executing it. Nothing destructive is ever run by this harness.
#
# Vulnerable-looking payloads are assembled at runtime from fragments, never
# stored as literals: this tree is published in a public dotfiles repo, and the
# local Write/Edit gate would reject a file containing them.
#
# Six assertion classes, each mapping to a bug class found in the 2026-08-10 audit:
#   1. Field extraction   — hooks read the fields Claude Code actually sends
#   2. Env contract       — no hook references the non-existent CLAUDE_SESSION_ID
#   3. Exit-code hygiene  — no hook exits non-zero on well-formed input
#   4. Output shape       — emitted JSON is valid and carries the right event name
#   5. Rulebook conformance — rulebook.json `tests` verdicts hold (Safety Net never runs them)
#   6. Rule scoping       — ccx rules use `paths:`, and those paths scope as intended

set -uo pipefail
shopt -s extglob

TESTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CLAUDE_DIR=$(dirname "$TESTS_DIR")
HOOKS_DIR="$CLAUDE_DIR/hooks"
FIXTURES="$TESTS_DIR/fixtures"
RULEBOOK="$HOME/.cc-safety-net/rules/antoine-personal/rulebook.json"
CCX_PROFILES="$HOME/.config/ccx/profiles"

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/claude-hook-contract.XXXXXX")
trap 'rm -rf "$SANDBOX"' EXIT

PASSED=0
FAILED=0
SKIPPED=0

pass() {
	PASSED=$((PASSED + 1))
	printf '  \033[32mPASS\033[0m %s\n' "$1"
}

fail() {
	FAILED=$((FAILED + 1))
	printf '  \033[31mFAIL\033[0m %s\n' "$1"
	[[ $# -gt 1 ]] && printf '       %s\n' "$2"
}

skip() {
	SKIPPED=$((SKIPPED + 1))
	printf '  \033[33mSKIP\033[0m %s — %s\n' "$1" "$2"
}

section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

require_deps() {
	local missing=()
	for dep in jq bash awk git; do
		command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		printf 'Missing required dependencies: %s\n' "${missing[*]}" >&2
		exit 1
	fi
}

# Run a hook with a JSON payload on stdin. Captures stdout, stderr and exit code
# into the globals HOOK_STDOUT / HOOK_STDERR / HOOK_RC.
run_hook() {
	local hook="$1" payload="$2"
	shift 2
	local out_file="$SANDBOX/stdout.$$" err_file="$SANDBOX/stderr.$$"
	HOOK_RC=0
	env "$@" bash "$HOOKS_DIR/$hook" >"$out_file" 2>"$err_file" <<<"$payload" || HOOK_RC=$?
	HOOK_STDOUT=$(cat "$out_file")
	HOOK_STDERR=$(cat "$err_file")
	rm -f "$out_file" "$err_file"
}

fixture() { cat "$FIXTURES/$1"; }

# A credential-shaped string in GitHub personal-token format.
fake_github_token() { printf 'ghp_%s' "$(printf 'a%.0s' {1..36})"; }

# A leaked-credential line, built from fragments so no assignment literal is stored.
leak_line() { printf '%s%s%s' 'token' '=' "$(fake_github_token)"; }

# A Java statement that concatenates user input into a query string.
injectable_query() {
	local verb
	verb=$(printf '%s%s' 'SEL' 'ECT')
	printf 'String q = "%s * FROM users WHERE id = " + userId;' "$verb"
}

# ── 1. Field extraction ──────────────────────────────────────────────────────
# Each assertion feeds a real captured payload and checks that the hook reacted
# to a field it could only have seen by reading the correct key.

test_field_extraction() {
	section "1. Field extraction"

	local leak
	leak=$(leak_line)

	# post-bash-security.sh must read .tool_response.stdout (Bash shape).
	local bash_payload
	bash_payload=$(fixture post-tool-use-bash.json |
		jq --arg leak "$leak" '.tool_response.stdout += "\n" + $leak')
	run_hook post-bash-security.sh "$bash_payload"
	if [[ "$HOOK_STDOUT" == *"SECRET LEAK WARNING"* && "$HOOK_STDOUT" == *"GitHub Token"* ]]; then
		pass "post-bash-security.sh reads .tool_response.stdout"
	else
		fail "post-bash-security.sh reads .tool_response.stdout" "stdout: ${HOOK_STDOUT:-<empty>}"
	fi

	# ...and .tool_response.content (Write shape). This is the exact field the
	# audit found broken: the hook used to read a non-existent .tool_output.
	local write_payload
	write_payload=$(fixture post-tool-use-write.json |
		jq --arg leak "$leak" '.tool_response.content += $leak + "\n"')
	run_hook post-bash-security.sh "$write_payload"
	if [[ "$HOOK_STDOUT" == *"GitHub Token"* ]]; then
		pass "post-bash-security.sh reads .tool_response.content"
	else
		fail "post-bash-security.sh reads .tool_response.content" "stdout: ${HOOK_STDOUT:-<empty>}"
	fi

	# A clean payload must stay silent — guards against a detector that fires on
	# the serialised envelope rather than on real output.
	run_hook post-bash-security.sh "$(fixture post-tool-use-write.json)"
	if [[ -z "$HOOK_STDOUT" ]]; then
		pass "post-bash-security.sh silent on clean output"
	else
		fail "post-bash-security.sh silent on clean output" "stdout: $HOOK_STDOUT"
	fi

	# security-gate.sh must read .tool_input.file_path and .tool_input.content.
	local query gate_payload
	query=$(injectable_query)
	gate_payload=$(jq -nc --arg c "$query" '{
	  hook_event_name: "PreToolUse",
	  tool_name: "Write",
	  tool_input: {file_path: "/tmp/Example.java", content: $c}
	}')
	run_hook security-gate.sh "$gate_payload"
	if [[ $HOOK_RC -eq 2 && "$HOOK_STDERR" == *"injection"* ]]; then
		pass "security-gate.sh reads .tool_input.content (query branch reachable)"
	else
		fail "security-gate.sh reads .tool_input.content (query branch reachable)" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
	fi

	# Same content, non-source extension: extension gating must short-circuit.
	local ignored_payload
	ignored_payload=$(jq -nc --arg c "$query" '{
	  hook_event_name: "PreToolUse",
	  tool_name: "Write",
	  tool_input: {file_path: "/tmp/notes.txt", content: $c}
	}')
	run_hook security-gate.sh "$ignored_payload"
	if [[ $HOOK_RC -eq 0 ]]; then
		pass "security-gate.sh reads .tool_input.file_path (extension gating)"
	else
		fail "security-gate.sh reads .tool_input.file_path (extension gating)" "rc=$HOOK_RC"
	fi

	# Kotlin must be gated as source too (item 5 widened the extension list).
	local kotlin_payload
	kotlin_payload=$(jq -nc --arg c "$query" '{
	  hook_event_name: "PreToolUse",
	  tool_name: "Write",
	  tool_input: {file_path: "/tmp/Example.kt", content: $c}
	}')
	run_hook security-gate.sh "$kotlin_payload"
	if [[ $HOOK_RC -eq 2 ]]; then
		pass "security-gate.sh treats .kt as source"
	else
		fail "security-gate.sh treats .kt as source" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
	fi

	# cwd-profile.sh must read .new_cwd, not .cwd. The payload points .cwd at a
	# plain directory and .new_cwd at a linked-worktree marker, so a hook reading
	# the wrong key produces no export.
	local worktree="$SANDBOX/linked-worktree" plain="$SANDBOX/plain-repo"
	mkdir -p "$worktree" "$plain"
	printf 'gitdir: %s/main/.git/worktrees/linked\n' "$SANDBOX" >"$worktree/.git"
	local env_file="$SANDBOX/claude-env"
	: >"$env_file"
	local cwd_payload
	cwd_payload=$(fixture cwd-changed.json |
		jq --arg wt "$worktree" --arg plain "$plain" '.new_cwd = $wt | .cwd = $plain')
	run_hook cwd-profile.sh "$cwd_payload" "CLAUDE_ENV_FILE=$env_file"
	if grep -qx 'SAFETY_NET_WORKTREE=1' "$env_file"; then
		pass "cwd-profile.sh reads .new_cwd (worktree detected)"
	else
		fail "cwd-profile.sh reads .new_cwd (worktree detected)" "env file: $(cat "$env_file")"
	fi

	# pre-compact-snapshot.sh must read CLAUDE_CODE_SESSION_ID and harvest the
	# activity log for that session.
	local sid fake_home log_dir log_file
	sid=$(fixture pre-compact.json | jq -r '.session_id')
	fake_home="$SANDBOX/home-precompact"
	log_dir="$fake_home/.claude/logs"
	mkdir -p "$log_dir"
	log_file="$log_dir/activity-$(date +%Y-%m-%d).jsonl"
	jq -nc --arg sid "$sid" '{timestamp: "2026-08-10T08:00:00Z", session_id: $sid, tool: "Write", file: "/home/antoine/projects/blog/content/about.md", project: "blog"}' >"$log_file"
	jq -nc --arg sid "$sid" '{timestamp: "2026-08-10T08:01:00Z", session_id: $sid, tool: "Bash", command: "mvn test -q", project: "blog"}' >>"$log_file"
	run_hook pre-compact-snapshot.sh "$(fixture pre-compact.json)" \
		"HOME=$fake_home" "CLAUDE_CODE_SESSION_ID=$sid"
	local state_dir="$fake_home/.claude/session-env/$sid"
	if [[ -s "$state_dir/files-modified.txt" ]] && grep -q 'content/about.md' "$state_dir/files-modified.txt"; then
		pass "pre-compact-snapshot.sh harvests files from the activity log"
	else
		fail "pre-compact-snapshot.sh harvests files from the activity log" "state dir: $(ls -1 "$state_dir" 2>/dev/null | tr '\n' ' ')"
	fi
	if [[ -s "$state_dir/tests-run.txt" ]] && grep -q 'mvn test' "$state_dir/tests-run.txt"; then
		pass "pre-compact-snapshot.sh harvests test commands from the activity log"
	else
		fail "pre-compact-snapshot.sh harvests test commands from the activity log" "tests-run: $(cat "$state_dir/tests-run.txt" 2>/dev/null)"
	fi

	# compact-reinjection.sh must read the same env var and the snapshot it wrote.
	run_hook compact-reinjection.sh "$(fixture session-start-compact.json)" \
		"HOME=$fake_home" "CLAUDE_CODE_SESSION_ID=$sid"
	if [[ "$HOOK_STDOUT" == *"content/about.md"* ]]; then
		pass "compact-reinjection.sh re-injects the snapshot"
	else
		fail "compact-reinjection.sh re-injects the snapshot" "stdout: ${HOOK_STDOUT:-<empty>}"
	fi

	# stash-reminder.sh must read .cwd and count open STASH.md items.
	local stash_home="$SANDBOX/home-stash" stash_cwd="$SANDBOX/stash-project"
	mkdir -p "$stash_home" "$stash_cwd"
	printf -- '# Stash\n\n- [ ] first open item\n- [x] done item\n- [ ] second open item\n' >"$stash_cwd/STASH.md"
	local stash_payload
	stash_payload=$(jq -nc --arg cwd "$stash_cwd" '{hook_event_name: "Stop", cwd: $cwd}')
	run_hook stash-reminder.sh "$stash_payload" \
		"HOME=$stash_home" "CLAUDE_CODE_SESSION_ID=contract-test-$$"
	if [[ "$HOOK_STDOUT" == *"2 open items"* ]]; then
		pass "stash-reminder.sh reads .cwd and counts open items"
	else
		fail "stash-reminder.sh reads .cwd and counts open items" "stdout: ${HOOK_STDOUT:-<empty>}"
	fi
	rm -f "/tmp/claude-stash-shown-contract-test-$$"
}

# ── 2. Env contract ──────────────────────────────────────────────────────────
# Claude Code exports CLAUDE_CODE_SESSION_ID. Three hooks silently no-op'd for
# months because they read CLAUDE_SESSION_ID, which does not exist.

test_env_contract() {
	section "2. Env contract"

	local offenders
	offenders=$(grep -rlE '(^|[^_A-Z])CLAUDE_SESSION_ID' "$HOOKS_DIR" 2>/dev/null || true)
	if [[ -z "$offenders" ]]; then
		pass "no hook references CLAUDE_SESSION_ID"
	else
		fail "no hook references CLAUDE_SESSION_ID" "$(tr '\n' ' ' <<<"$offenders")"
	fi

	local users
	users=$(grep -rl 'CLAUDE_CODE_SESSION_ID' "$HOOKS_DIR" 2>/dev/null | wc -l | tr -dc '0-9')
	if [[ "$users" -ge 3 ]]; then
		pass "session-scoped hooks use CLAUDE_CODE_SESSION_ID ($users files)"
	else
		fail "session-scoped hooks use CLAUDE_CODE_SESSION_ID" "expected >= 3 files, found $users"
	fi
}

# ── 3. Exit-code hygiene ─────────────────────────────────────────────────────
# `set -euo pipefail` plus an unbound variable aborts a hook mid-flight. Every
# hook must exit 0 on a well-formed payload and on a minimal one.

test_exit_codes() {
	section "3. Exit-code hygiene"

	local -a cases=(
		"auto-format.sh|post-tool-use-write.json"
		"post-bash-security.sh|post-tool-use-bash.json"
		"post-bash-security.sh|post-tool-use-write.json"
		"repo-integrity-scanner.sh|pre-tool-use-bash.json"
		"cwd-profile.sh|cwd-changed.json"
		"pre-compact-snapshot.sh|pre-compact.json"
		"compact-reinjection.sh|session-start-compact.json"
		"session-orientation.sh|session-start-compact.json"
	)

	local entry hook fx
	for entry in "${cases[@]}"; do
		hook=${entry%%|*}
		fx=${entry##*|}
		run_hook "$hook" "$(fixture "$fx")" "HOME=$SANDBOX/home-exit" "CLAUDE_CODE_SESSION_ID=contract-test-$$"
		if [[ $HOOK_RC -eq 0 ]]; then
			pass "$hook exits 0 on $fx"
		else
			fail "$hook exits 0 on $fx" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
		fi
	done

	local benign_java
	benign_java=$(jq -nc '{
	  hook_event_name: "PreToolUse",
	  tool_name: "Write",
	  tool_input: {file_path: "/tmp/Benign.java", content: "record User(String id) {}\n"}
	}')
	run_hook security-gate.sh "$benign_java"
	if [[ $HOOK_RC -eq 0 ]]; then
		pass "security-gate.sh exits 0 on benign source"
	else
		fail "security-gate.sh exits 0 on benign source" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
	fi

	# Minimal well-formed JSON: no tool, no cwd. This is the `set -u` trap.
	local hook_file
	for hook_file in "$HOOKS_DIR"/*.sh; do
		hook=$(basename "$hook_file")
		run_hook "$hook" '{}' "HOME=$SANDBOX/home-exit" "CLAUDE_CODE_SESSION_ID=contract-test-$$"
		if [[ $HOOK_RC -eq 0 ]]; then
			pass "$hook exits 0 on minimal payload"
		else
			fail "$hook exits 0 on minimal payload" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
		fi
	done
	rm -f "/tmp/claude-stash-shown-contract-test-$$"
}

# ── 4. Output shape ──────────────────────────────────────────────────────────
# PostToolUse/Stop hooks emit {systemMessage}. SessionStart hooks must emit
# hookSpecificOutput with hookEventName "SessionStart" — the only injection path.

test_output_shape() {
	section "4. Output shape"

	local shape_home="$SANDBOX/home-shape" sid="contract-shape-$$"
	mkdir -p "$shape_home/.claude/session-env/$sid"
	printf '/home/antoine/projects/blog/content/about.md\n' >"$shape_home/.claude/session-env/$sid/files-modified.txt"

	run_hook compact-reinjection.sh "$(fixture session-start-compact.json)" \
		"HOME=$shape_home" "CLAUDE_CODE_SESSION_ID=$sid"
	if jq -e '.hookSpecificOutput.hookEventName == "SessionStart" and (.hookSpecificOutput.additionalContext | length) > 0' <<<"$HOOK_STDOUT" >/dev/null 2>&1; then
		pass "compact-reinjection.sh emits SessionStart hookSpecificOutput"
	else
		fail "compact-reinjection.sh emits SessionStart hookSpecificOutput" "stdout: ${HOOK_STDOUT:-<empty>}"
	fi

	# A repo with at least one commit: session-orientation.sh reads `git log`, and
	# a commitless repo makes that call fail (tracked separately, not a contract
	# this harness asserts).
	local repo="$SANDBOX/orientation-repo"
	mkdir -p "$repo"
	git -C "$repo" init -q 2>/dev/null
	git -C "$repo" commit -q --allow-empty -m "fixture commit" 2>/dev/null
	local orient_payload
	orient_payload=$(jq -nc --arg cwd "$repo" '{hook_event_name: "SessionStart", source: "startup", cwd: $cwd}')
	run_hook session-orientation.sh "$orient_payload" "HOME=$shape_home"
	if jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' <<<"$HOOK_STDOUT" >/dev/null 2>&1; then
		pass "session-orientation.sh emits SessionStart hookSpecificOutput"
	else
		fail "session-orientation.sh emits SessionStart hookSpecificOutput" "stdout: ${HOOK_STDOUT:-<empty>}"
	fi

	local leak_payload
	leak_payload=$(fixture post-tool-use-bash.json |
		jq --arg leak "$(leak_line)" '.tool_response.stdout += "\n" + $leak')
	run_hook post-bash-security.sh "$leak_payload"
	if jq -e '(.systemMessage | length) > 0' <<<"$HOOK_STDOUT" >/dev/null 2>&1; then
		pass "post-bash-security.sh emits a valid systemMessage object"
	else
		fail "post-bash-security.sh emits a valid systemMessage object" "stdout: ${HOOK_STDOUT:-<empty>}"
	fi

	local stash_cwd="$SANDBOX/stash-shape"
	mkdir -p "$stash_cwd"
	printf -- '- [ ] open item\n' >"$stash_cwd/STASH.md"
	local stash_payload
	stash_payload=$(jq -nc --arg cwd "$stash_cwd" '{hook_event_name: "Stop", cwd: $cwd}')
	run_hook stash-reminder.sh "$stash_payload" "HOME=$shape_home" "CLAUDE_CODE_SESSION_ID=contract-shape2-$$"
	if jq -e '(.systemMessage | length) > 0' <<<"$HOOK_STDOUT" >/dev/null 2>&1; then
		pass "stash-reminder.sh emits a valid systemMessage object"
	else
		fail "stash-reminder.sh emits a valid systemMessage object" "stdout: ${HOOK_STDOUT:-<empty>}"
	fi
	rm -f "/tmp/claude-stash-shown-contract-shape2-$$"
}

# ── 5. Rulebook conformance ──────────────────────────────────────────────────
# Safety Net shape-validates rulebook `tests` but never executes them. Without
# this class they are decorative comments. `explain` analyses, never executes.

test_rulebook_conformance() {
	section "5. Rulebook conformance"

	if ! command -v cc-safety-net >/dev/null 2>&1; then
		skip "rulebook conformance" "cc-safety-net not on PATH"
		return
	fi
	if [[ ! -f "$RULEBOOK" ]]; then
		skip "rulebook conformance" "no rulebook at $RULEBOOK"
		return
	fi

	local active
	active=$(cc-safety-net rule list 2>/dev/null | grep -c 'antoine-personal' || true)
	if [[ "$active" -gt 0 ]]; then
		pass "rulebook antoine-personal is active"
	else
		fail "rulebook antoine-personal is active" "not listed by 'cc-safety-net rule list'"
	fi

	local total
	total=$(jq -r '.tests | length' "$RULEBOOK")
	if [[ "$total" -eq 0 ]]; then
		fail "rulebook declares test fixtures" "tests[] is empty"
		return
	fi

	local i cmd expect want_rule verdict rule_id analysis
	for ((i = 0; i < total; i++)); do
		cmd=$(jq -r ".tests[$i].command" "$RULEBOOK")
		expect=$(jq -r ".tests[$i].expect" "$RULEBOOK")
		want_rule=$(jq -r ".tests[$i].rule // empty" "$RULEBOOK")

		analysis=$(cc-safety-net explain --json "$cmd" 2>/dev/null)
		verdict=$(jq -r '.result // "error"' <<<"$analysis")
		rule_id=$(jq -r '.ruleId // ""' <<<"$analysis")

		if [[ "$verdict" != "$expect" ]]; then
			fail "explain '$cmd' -> $expect" "got '$verdict'"
			continue
		fi
		if [[ -n "$want_rule" && "$rule_id" != *"$want_rule" ]]; then
			fail "explain '$cmd' -> $expect via $want_rule" "matched ruleId '$rule_id'"
			continue
		fi
		pass "explain '$cmd' -> $expect${want_rule:+ via $want_rule}"
	done

	# The rtk transparent wrapper must unwrap to the inner command, or every
	# rewritten command bypasses the rulebook.
	local wrapped
	wrapped=$(cc-safety-net explain --json 'rtk npm install -g typescript' 2>/dev/null | jq -r '.result // "error"')
	if [[ "$wrapped" == "blocked" ]]; then
		pass "rtk transparent wrapper unwraps to the inner command"
	else
		fail "rtk transparent wrapper unwraps to the inner command" "got '$wrapped'"
	fi
}

# ── 6. Rule scoping ──────────────────────────────────────────────────────────
# `globs:` is not a valid ccx frontmatter key: a rule using it loads in every
# session instead of only where it applies. Assert the key is gone and that the
# `paths:` patterns actually scope.

# Translate a Claude-style glob into a bash extglob pattern:
#   `**/` -> zero or more directories, `{a,b}` -> @(a|b)
pattern_to_bash() {
	local p="$1"
	p=${p//\*\*\//@(*\/|)}
	while [[ "$p" == *'{'*','*'}'* ]]; do
		local prefix=${p%%\{*} rest=${p#*\{}
		local body=${rest%%\}*} suffix=${rest#*\}}
		p="${prefix}@(${body//,/|})${suffix}"
	done
	printf '%s' "$p"
}

rule_paths() {
	awk '
	  /^paths:[[:space:]]*$/ { inpaths = 1; next }
	  inpaths && /^[[:space:]]*-[[:space:]]/ {
	    line = $0
	    sub(/^[[:space:]]*-[[:space:]]*/, "", line)
	    gsub(/^"|"$/, "", line)
	    print line
	    next
	  }
	  inpaths { inpaths = 0 }
	' "$1"
}

matches_any() {
	local candidate="$1" file="$2" raw bash_pattern
	while IFS= read -r raw; do
		[[ -z "$raw" ]] && continue
		bash_pattern=$(pattern_to_bash "$raw")
		# shellcheck disable=SC2053 # intentional glob match, not a literal compare
		[[ "$candidate" == $bash_pattern ]] && return 0
	done < <(rule_paths "$file")
	return 1
}

test_rule_scoping() {
	section "6. Rule scoping"

	if [[ ! -d "$CCX_PROFILES" ]]; then
		skip "rule scoping" "no ccx profiles at $CCX_PROFILES"
		return
	fi

	local offenders
	offenders=$(grep -rl 'globs:' "$CCX_PROFILES" 2>/dev/null || true)
	if [[ -z "$offenders" ]]; then
		pass "no ccx rule file uses the invalid 'globs:' key"
	else
		fail "no ccx rule file uses the invalid 'globs:' key" "$(tr '\n' ' ' <<<"$offenders")"
	fi

	# rule file | path that must be in scope | path that must be out of scope
	local -a expectations=(
		"hugo/rules/hugo-content.md|content/posts/first.md|layouts/partials/head.html"
		"java-jenkins/rules/jenkins-security.md|src/main/java/MyBuilder.java|docs/README.md"
		"java-jenkins/rules/jenkins-security.md|src/main/resources/config.jelly|docs/README.md"
		"java-persistence/rules/persistence-safety.md|src/main/java/domain/User.java|src/main/java/util/Helper.java"
		"java-release/rules/native-image-safety.md|src/main/java/Main.java|src/test/java/MainTest.java"
		"java-security/rules/security-safety.md|src/main/java/Auth.java|src/main/kotlin/Auth.kt"
	)

	local entry rel positive negative file
	for entry in "${expectations[@]}"; do
		IFS='|' read -r rel positive negative <<<"$entry"
		file="$CCX_PROFILES/$rel"
		if [[ ! -f "$file" ]]; then
			skip "scoping $rel" "file not found"
			continue
		fi
		if [[ -z "$(rule_paths "$file")" ]]; then
			fail "scoping $rel" "no 'paths:' list found"
			continue
		fi
		if matches_any "$positive" "$file"; then
			pass "scoping $rel matches $positive"
		else
			fail "scoping $rel matches $positive" "patterns: $(rule_paths "$file" | tr '\n' ' ')"
		fi
		if matches_any "$negative" "$file"; then
			fail "scoping $rel excludes $negative" "patterns: $(rule_paths "$file" | tr '\n' ' ')"
		else
			pass "scoping $rel excludes $negative"
		fi
	done
}

main() {
	require_deps
	printf '\033[1mHook contract tests\033[0m — %s\n' "$HOOKS_DIR"

	test_field_extraction
	test_env_contract
	test_exit_codes
	test_output_shape
	test_rulebook_conformance
	test_rule_scoping

	printf '\n\033[1mSummary\033[0m: %d passed, %d failed, %d skipped\n' "$PASSED" "$FAILED" "$SKIPPED"
	[[ $FAILED -eq 0 ]]
}

main "$@"
