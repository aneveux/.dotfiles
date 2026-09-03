#!/usr/bin/env bash
# Hook contract tests for ~/.claude/hooks and the CC Safety Net rulebook.
#
# SAFETY PRINCIPLE, NON-NEGOTIABLE: test the DETECTORS, never the PAYLOADS.
# Dangerous or secret-shaped strings only ever travel as JSON data on a hook's
# stdin, or as an argument to `cc-safety-net explain`, which analyses a command
# without executing it. Nothing destructive is ever run by this harness.
#
# Vulnerable-looking payloads are assembled at runtime from fragments, never
# stored as literals: this tree gets published, and the local Write/Edit gate
# would reject a file containing them.
#
# Eight assertion classes, each mapping to a bug class found in the audits:
#   1. Field extraction   — hooks read the fields Claude Code actually sends
#   2. Env contract       — no hook references the non-existent CLAUDE_SESSION_ID
#   3. Exit-code hygiene  — no hook exits non-zero on well-formed input
#   4. Output shape       — emitted JSON is valid and carries the right event name
#   5. Rulebook conformance — rulebook.json `tests` verdicts hold (Safety Net never runs them)
#   6. Rule scoping       — ccx rules use `paths:`, and those paths scope as intended
#   7. Handover content   — the context hook emits real content, not just exit 0
#   8. Config guard       — the deny-rule floor blocks and allows in the right cases

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
	for dep in jq bash awk; do
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

# A credential-shaped string in GitHub personal-token format, built from
# fragments so no literal token lands in this file.
fake_github_token() { printf 'ghp_%s' "$(printf 'a%.0s' {1..36})"; }

# A source line assigning that credential to a constant.
leaked_credential_line() {
	printf 'String t = "%s";' "$(fake_github_token)"
}

# A source line carrying a zero-width space (U+200B), written as its UTF-8 bytes
# so no invisible character is stored in this file.
zero_width_line() { printf 'int a = 1;\xe2\x80\x8b\n'; }

# ── 1. Field extraction ──────────────────────────────────────────────────────
# Each assertion feeds a real captured payload and checks that the hook reacted
# to a field it could only have seen by reading the correct key.

test_field_extraction() {
	section "1. Field extraction"

	# security-gate.sh must read .tool_input.file_path and .tool_input.content.
	local query gate_payload
	query=$(leaked_credential_line)
	gate_payload=$(jq -nc --arg c "$query" '{
	  hook_event_name: "PreToolUse",
	  tool_name: "Write",
	  tool_input: {file_path: "/tmp/Example.java", content: $c}
	}')
	run_hook security-gate.sh "$gate_payload"
	if [[ $HOOK_RC -eq 2 && "$HOOK_STDERR" == *"API key"* ]]; then
		pass "security-gate.sh reads .tool_input.content (credential branch reachable)"
	else
		fail "security-gate.sh reads .tool_input.content (credential branch reachable)" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
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

	# Maven/properties files carry credentials too, so they must be gated as source.
	local xml_payload
	xml_payload=$(jq -nc --arg c "$query" '{
	  hook_event_name: "PreToolUse",
	  tool_name: "Write",
	  tool_input: {file_path: "/tmp/pom.xml", content: $c}
	}')
	run_hook security-gate.sh "$xml_payload"
	if [[ $HOOK_RC -eq 2 ]]; then
		pass "security-gate.sh treats .xml as source"
	else
		fail "security-gate.sh treats .xml as source" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
	fi

	# Invisible-character blocking is the other half of the narrowed gate.
	local zw_payload
	zw_payload=$(jq -nc --arg c "$(zero_width_line)" '{
	  hook_event_name: "PreToolUse",
	  tool_name: "Write",
	  tool_input: {file_path: "/tmp/Example.java", content: $c}
	}')
	run_hook security-gate.sh "$zw_payload"
	if [[ $HOOK_RC -eq 2 && "$HOOK_STDERR" == *"Zero-width"* ]]; then
		pass "security-gate.sh blocks a zero-width character"
	else
		fail "security-gate.sh blocks a zero-width character" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
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

	# Zero open items must stay silent: `grep -c` exits 1 when nothing matches.
	local quiet_cwd="$SANDBOX/stash-quiet"
	mkdir -p "$quiet_cwd"
	printf -- '# Stash\n\n- [x] done item\n' >"$quiet_cwd/STASH.md"
	local quiet_payload
	quiet_payload=$(jq -nc --arg cwd "$quiet_cwd" '{hook_event_name: "Stop", cwd: $cwd}')
	run_hook stash-reminder.sh "$quiet_payload" \
		"HOME=$stash_home" "CLAUDE_CODE_SESSION_ID=contract-quiet-$$"
	if [[ $HOOK_RC -eq 0 && -z "$HOOK_STDOUT" && -z "$HOOK_STDERR" ]]; then
		pass "stash-reminder.sh stays silent with zero open items"
	else
		fail "stash-reminder.sh stays silent with zero open items" \
			"rc=$HOOK_RC stdout: ${HOOK_STDOUT:-<empty>} stderr: ${HOOK_STDERR:-<empty>}"
	fi
	rm -f "/tmp/claude-stash-shown-contract-quiet-$$"
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
	if [[ "$users" -ge 1 ]]; then
		pass "session-scoped hooks use CLAUDE_CODE_SESSION_ID ($users files)"
	else
		fail "session-scoped hooks use CLAUDE_CODE_SESSION_ID" "expected >= 1 file, found $users"
	fi
}

# ── 3. Exit-code hygiene ─────────────────────────────────────────────────────
# `set -euo pipefail` plus an unbound variable aborts a hook mid-flight. Every
# hook must exit 0 on a well-formed payload and on a minimal one.

test_exit_codes() {
	section "3. Exit-code hygiene"

	local -a cases=(
		"auto-format.sh|post-tool-use-write.json"
		"repo-integrity-scanner.sh|pre-tool-use-bash.json"
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
# PostToolUse/Stop hooks emit {systemMessage}. A hook whose stdout is not valid
# JSON of the expected shape is discarded silently.

test_output_shape() {
	section "4. Output shape"

	local shape_home="$SANDBOX/home-shape"
	mkdir -p "$shape_home/.claude"

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
		"bash/rules/bash-safety.md|scripts/deploy.sh|src/main/java/App.java"
		"java/rules/java-safety.md|src/main/java/App.java|README.md"
		"java/rules/java.md|src/main/java/App.java|README.md"
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

# ── 7. Handover content ──────────────────────────────────────────────────────
# The deleted compaction feature passed exit-code tests while producing empty
# output. These assertions require non-empty, well-formed content, and verify
# that the hook actually read the transcript field it claims to extract.

test_handover_content() {
	section "7. Handover content"

	local fake_tp="$SANDBOX/handover-fixture.jsonl"

	# Minimal transcript: ai-title + last-prompt + one Write tool_use
	jq -nc '{type:"ai-title",aiTitle:"test-session-title",sessionId:"s1"}' >"$fake_tp"
	jq -nc '{type:"last-prompt",lastPrompt:"do the thing",sessionId:"s1"}' >>"$fake_tp"
	jq -nc '{
	  type:"assistant",sessionId:"s1",
	  message:{role:"assistant",content:[{
	    type:"tool_use",id:"t1",name:"Write",
	    input:{file_path:"src/app.ts",content:"export const x = 1"}
	  }]}
	}' >>"$fake_tp"

	local compact_payload
	compact_payload=$(jq -nc \
		--arg tp "$fake_tp" \
		'{hook_event_name:"SessionStart",source:"compact",
		  transcript_path:$tp,session_id:"contract-ho-$$",cwd:"/tmp"}')

	run_hook session-handover.sh "$compact_payload" \
		"HOME=$SANDBOX/home-ho" "CLAUDE_CODE_SESSION_ID=contract-ho-$$"

	if [[ $HOOK_RC -eq 0 ]]; then
		pass "session-handover.sh exits 0 on compact payload"
	else
		fail "session-handover.sh exits 0 on compact payload" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
	fi

	if [[ -n "$HOOK_STDOUT" ]]; then
		pass "session-handover.sh stdout is non-empty (anti-regression: deleted version was always empty)"
	else
		fail "session-handover.sh stdout is non-empty (anti-regression: deleted version was always empty)" "stdout was empty"
	fi

	if [[ "$HOOK_STDOUT" == *"src/app.ts"* ]]; then
		pass "session-handover.sh output contains extracted file path (read transcript)"
	else
		fail "session-handover.sh output contains extracted file path (read transcript)" "stdout: ${HOOK_STDOUT:-<empty>}"
	fi

	# session-end-pointer: write then verify the pointer file
	local ptr_home="$SANDBOX/home-ptr"
	mkdir -p "$ptr_home/.claude/session-env"

	local ptr_payload
	ptr_payload=$(jq -nc \
		--arg tp "$fake_tp" \
		'{hook_event_name:"SessionEnd",reason:"clear",
		  transcript_path:$tp,session_id:"contract-ptr-$$",cwd:"/tmp"}')

	run_hook session-end-pointer.sh "$ptr_payload" \
		"HOME=$ptr_home" "CLAUDE_CODE_SESSION_ID=contract-ptr-$$"

	if [[ $HOOK_RC -eq 0 ]]; then
		pass "session-end-pointer.sh exits 0 on clear payload"
	else
		fail "session-end-pointer.sh exits 0 on clear payload" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
	fi

	local ptr_file
	ptr_file=$(find "$ptr_home" -name "last-clear.json" 2>/dev/null | head -1)

	if [[ -n "$ptr_file" && -f "$ptr_file" ]]; then
		pass "session-end-pointer.sh wrote last-clear.json"
	else
		fail "session-end-pointer.sh wrote last-clear.json" "no file found under $ptr_home"
	fi

	if [[ -n "$ptr_file" ]] && jq -e '.session_id == "contract-ptr-'"$$"'"' "$ptr_file" >/dev/null 2>&1; then
		pass "last-clear.json contains correct session_id"
	else
		fail "last-clear.json contains correct session_id" "contents: $(cat "$ptr_file" 2>/dev/null || echo '<missing>')"
	fi

	rm -rf "$ptr_home"
}

# ── 8. Config guard ──────────────────────────────────────────────────────────
# The guard of the guards had no coverage at all. It also treated a missing
# settings.json as "the deny rules were deleted", which blocked every config
# change under a fresh HOME. Both directions matter here: a guard that stops
# blocking is as broken as one that always blocks, and the second failure mode
# is the one nothing would have noticed.

# Write a settings.json with $1 deny rules into a throwaway HOME, echo the HOME.
guard_home() {
	local count="$1"
	local home="$SANDBOX/guard-$count-$RANDOM"
	mkdir -p "$home/.claude"
	jq -nc --argjson n "$count" \
		'{permissions: {deny: [range($n) | "Bash(fake-rule-\(.))"]}}' \
		>"$home/.claude/settings.json"
	printf '%s' "$home"
}

# The floor the hook enforces, read from the hook rather than hardcoded here, so
# the two cannot drift apart.
guard_floor() {
	sed -n 's/^FLOOR=\([0-9]\{1,\}\).*/\1/p' "$HOOKS_DIR/config-guard.sh" | head -1
}

test_config_guard() {
	section "8. Config guard"

	local floor
	floor=$(guard_floor)
	if [[ -z $floor ]]; then
		fail "config-guard.sh declares a FLOOR" "no FLOOR= assignment found"
		return
	fi
	pass "config-guard.sh declares a FLOOR ($floor)"

	# Absent settings file: nothing to guard, must allow. This is the assertion
	# that used to fail, and the reason the hook was rewritten.
	local empty_home="$SANDBOX/guard-empty-$RANDOM"
	mkdir -p "$empty_home"
	run_hook config-guard.sh '{}' "HOME=$empty_home"
	if [[ $HOOK_RC -eq 0 ]]; then
		pass "config-guard.sh allows when settings.json is absent"
	else
		fail "config-guard.sh allows when settings.json is absent" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
	fi

	# At the floor: allow.
	run_hook config-guard.sh '{}' "HOME=$(guard_home "$floor")"
	if [[ $HOOK_RC -eq 0 ]]; then
		pass "config-guard.sh allows exactly $floor deny rules"
	else
		fail "config-guard.sh allows exactly $floor deny rules" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
	fi

	# One below the floor: block. Without this, the hook could be reduced to
	# `exit 0` and every other assertion would still pass.
	run_hook config-guard.sh '{}' "HOME=$(guard_home $((floor - 1)))"
	if [[ $HOOK_RC -eq 2 ]]; then
		pass "config-guard.sh blocks $((floor - 1)) deny rules"
	else
		fail "config-guard.sh blocks $((floor - 1)) deny rules" "rc=$HOOK_RC (expected 2)"
	fi

	# permissions.deny removed entirely: block.
	local stripped="$SANDBOX/guard-stripped-$RANDOM"
	mkdir -p "$stripped/.claude"
	jq -nc '{permissions: {allow: []}}' >"$stripped/.claude/settings.json"
	run_hook config-guard.sh '{}' "HOME=$stripped"
	if [[ $HOOK_RC -eq 2 ]]; then
		pass "config-guard.sh blocks when permissions.deny is missing"
	else
		fail "config-guard.sh blocks when permissions.deny is missing" "rc=$HOOK_RC (expected 2)"
	fi

	# Malformed JSON: block rather than read as zero and report a count.
	local broken="$SANDBOX/guard-broken-$RANDOM"
	mkdir -p "$broken/.claude"
	printf '{"permissions": {"deny": [' >"$broken/.claude/settings.json"
	run_hook config-guard.sh '{}' "HOME=$broken"
	if [[ $HOOK_RC -eq 2 && $HOOK_STDERR == *"no deny-rule count"* ]]; then
		pass "config-guard.sh blocks on malformed settings.json"
	else
		fail "config-guard.sh blocks on malformed settings.json" "rc=$HOOK_RC stderr: ${HOOK_STDERR:-<empty>}"
	fi

	# deny as a non-list: block. `length` on a string returns a number, so an
	# unguarded count check would happily compare it against the floor.
	local wrong_type="$SANDBOX/guard-type-$RANDOM"
	mkdir -p "$wrong_type/.claude"
	jq -nc '{permissions: {deny: "everything"}}' >"$wrong_type/.claude/settings.json"
	run_hook config-guard.sh '{}' "HOME=$wrong_type"
	if [[ $HOOK_RC -eq 2 ]]; then
		pass "config-guard.sh blocks when permissions.deny is not a list"
	else
		fail "config-guard.sh blocks when permissions.deny is not a list" "rc=$HOOK_RC (expected 2)"
	fi

	# FLOOR must match the settings file shipped next to the hooks, otherwise the
	# guard either blocks every legitimate change or has stopped counting.
	local reference=""
	[[ -f "$CLAUDE_DIR/settings.json" ]] && reference="$CLAUDE_DIR/settings.json"
	[[ -z $reference && -f "$CLAUDE_DIR/config/settings.json" ]] && reference="$CLAUDE_DIR/config/settings.json"
	if [[ -z $reference ]]; then
		skip "FLOOR matches the reference settings" "no settings.json next to $HOOKS_DIR"
	else
		local actual
		actual=$(jq '.permissions.deny // [] | length' "$reference" 2>/dev/null || echo -1)
		if [[ $actual -eq $floor ]]; then
			pass "FLOOR matches $(basename "$(dirname "$reference")")/$(basename "$reference") ($actual rules)"
		else
			fail "FLOOR matches $reference" "FLOOR=$floor but the file has $actual deny rules"
		fi
	fi
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
	test_handover_content
	test_config_guard

	printf '\n\033[1mSummary\033[0m: %d passed, %d failed, %d skipped\n' "$PASSED" "$FAILED" "$SKIPPED"
	[[ $FAILED -eq 0 ]]
}

main "$@"
