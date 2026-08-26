#!/bin/bash
# Repository Integrity Scanner Hook
# Event: PreToolUse:Read — scan files for injection vectors before processing
#
# Detects prompt injection attempts hidden in:
#   - README.md, SECURITY.md, CLAUDE.md (hidden HTML comments with instructions)
#   - package.json (malicious scripts)
#   - .claude/, .cursor/ configs (tampered configurations)
#
# Exit codes:
#   0 = allow (safe or not a target file)
#   2 = block (injection detected)

set -euo pipefail

INPUT=$(cat)

# Unparseable input is not a safe file: every jq below would yield empty, the
# tool-name test would fall through, and the read would pass unscanned.
if ! jq -e . >/dev/null 2>&1 <<<"$INPUT"; then
	echo "REPO-SCANNER: unparseable hook input, refusing to pass an unscanned read" >&2
	exit 2
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

[[ "$TOOL_NAME" != "Read" ]] && exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# Whitelist: never scan own config/hooks directory. Canonicalise both sides, or
# $HOME/.claude/../projects/x/README.md walks straight past the prefix test.
CLAUDE_HOME=$(readlink -f "$HOME/.claude" 2>/dev/null || printf '%s' "$HOME/.claude")
REAL_PATH=$(readlink -f "$FILE_PATH" 2>/dev/null || printf '%s' "$FILE_PATH")
[[ "$REAL_PATH" == "$CLAUDE_HOME/"* ]] && exit 0

FILENAME=$(basename "$REAL_PATH")
DIRNAME=$(dirname "$REAL_PATH")

# === HIGH-RISK FILES ===
HIGH_RISK_FILES=(
	"README.md"
	"readme.md"
	"SECURITY.md"
	"CONTRIBUTING.md"
	"CLAUDE.md"
	"CLAUDE.local.md"
)

# === CONFIG FILES ===
CONFIG_FILES=(
	"package.json"
	"pyproject.toml"
	"setup.py"
	"setup.cfg"
	"Makefile"
	".pre-commit-config.yaml"
)

# === IDE CONFIG PATTERNS ===
IDE_CONFIG_PATTERNS=(
	".cursor"
	".vscode"
	".idea"
	".claude"
)

# Match text against a case-insensitive ERE. A here-string, never a pipe: with
# `echo "$content" | grep -q`, grep exits on first match before echo finishes
# writing, and under pipefail the resulting SIGPIPE reads as "no match". That is
# a race, not a threshold: the earliest induced failure measured was 72 KB,
# roughly even odds at 100 KB, and deterministic above ~1 MB. A grep exit that
# is not a clean "no match" means the detector itself broke, which is not
# evidence the file is safe: block instead of waving it through.
matches() {
	local pattern="$1" text="$2" rc=0
	LC_ALL=C grep -qiE "$pattern" <<<"$text" || rc=$?
	case $rc in
	0) return 0 ;;
	1) return 1 ;;
	*)
		echo "REPO-SCANNER: detector failed (grep rc=$rc) on $FILE_PATH" >&2
		exit 2
		;;
	esac
}

check_injection_patterns() {
	local file="$1"
	local content flat
	content=$(cat "$file" 2>/dev/null || echo "")
	# grep is line-based, so an injection wrapped across two lines evades every
	# phrase pattern below. Match the role-override set against a flattened copy:
	# for patterns carrying no ^ or $ anchor its match set is a strict superset.
	flat=$(tr '\n' ' ' <<<"$content")

	# Hidden HTML comments with instruction-like content (require verb + target).
	# Stays line-based and keeps the closing --> : flattened, the .* spans would
	# reach from the first comment in the file to the last.
	if matches '<!--.*((ignore|disregard|forget)[^>]{0,30}(previous|prior|earlier|preceding|above|all|any|your)[^>]{0,30}(instruction|prompt|directive)|(override|bypass)[^>]{0,20}(instructions|system|prompt|safety)|execute (this|the following)|you are now (a|an|the)|new instructions:|<\|(im_start|system)\|>).*-->' "$content"; then
		echo "BLOCKED: Hidden HTML comment with injection instructions in: $file" >&2
		return 1
	fi

	# Explicit role override. Each phrase is anchored on an injection target,
	# because bare 'you are now' and 'from now on you must' are ordinary English
	# and blocked README lines like "You are now ready to deploy." Verb and
	# target groups are deliberately not cross-joined: 'override the default
	# rules' is common documentation, so 'override' pairs only with prompt-level
	# targets, and 'new instructions:' has to be followed by something addressed
	# at the model.
	if matches '(ignore|disregard|forget)[^.]{0,30}(previous|prior|earlier|preceding|above|all|any|your|the)[^.]{0,30}(instruction|prompt|directive)s?|(ignore|disregard|forget)[[:space:]]+(everything|all|anything)[^.]{0,20}(above|before|prior|preceding|earlier)|(override|bypass|circumvent)[^.]{0,30}(system prompt|these instructions|your instructions|the instructions|safety|guardrail)|you[[:space:]]+are[[:space:]]+now[^.]{0,40}(assistant|model|chatbot|dan\b|developer mode|unrestricted|unfiltered|jailbroken|no restrictions)|from[[:space:]]+now[[:space:]]+on,?[^.]{0,60}(ignore|disregard|reveal|obey|comply|no longer|without restriction|unrestricted)|new[[:space:]]+instructions?:[^.]{0,80}(you|your|assistant|model|system|secret|key|token|password|credential|env)|<\|(im_start|im_end|system|user|assistant|endoftext)\|>|\[/?INST\]|</(instructions|system|system_prompt)>|(^|[^[:alnum:]])(system|assistant)[[:space:]]*:[[:space:]]*(you[[:space:]]+(must|will|should|are|need)|ignore|disregard|execute|run|send|exfiltrate|reveal)' "$flat"; then
		echo "BLOCKED: Prompt injection pattern detected in: $file" >&2
		return 1
	fi

	# Base64 in comments containing injection keywords. Every comment line is
	# examined and every long token on it, bounded at 200 candidates: with
	# `grep -m1` plus `head -1`, one decoy comment carrying a plain hash was
	# enough to mask a real payload further down the file.
	local line token decoded scanned=0
	while IFS= read -r line; do
		[[ $scanned -ge 200 ]] && break
		while IFS= read -r token; do
			[[ $scanned -ge 200 ]] && break
			scanned=$((scanned + 1))
			decoded=$(base64 -d <<<"$token" 2>/dev/null || true)
			[[ -z "$decoded" ]] && continue
			case "${decoded,,}" in
			*ignore* | *override* | *system* | *jailbreak*)
				echo "BLOCKED: Base64-encoded injection detected in: $file" >&2
				return 1
				;;
			esac
		done < <(LC_ALL=C grep -oE '[A-Za-z0-9+/]{40,}={0,2}' <<<"$line" || true)
	done < <(LC_ALL=C grep -E '(#|//|<!--).*[A-Za-z0-9+/]{40,}={0,2}' <<<"$content" || true)

	return 0
}

check_package_json() {
	local file="$1"

	local scripts
	# Flattened: a script value carrying a literal newline would otherwise split a
	# pipeline across two grep lines. None of the patterns below is anchored, and
	# none can bridge two entries (the separators they need are excluded from the
	# spans they scan), so flattening only widens what is caught.
	scripts=$(jq -r '.scripts // {} | to_entries[] | "\(.key): \(.value)"' "$file" 2>/dev/null | tr '\n' ' ' || echo "")

	# Remote execution and reverse shells, anchored on a real pipe, redirection or
	# flag. The original forms were written as shell pipelines but evaluated as
	# EREs, so "wget.*|.*sh" meant "contains wget OR contains sh" and blocked
	# every package.json mentioning bash, sharp, publish or --no-content-hash.
	# Fetch-then-execute deliberately allows only shells as the executor, because
	# `curl -o config.json $URL && node server.js` is ordinary tooling.
	SUSPICIOUS_PATTERNS=(
		'(curl|wget|fetch)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+|env[[:space:]]+[^[:space:]]+[[:space:]]+)*((ba|z|k|da)?sh|node|python[23]?|perl|ruby|php)([[:space:]]|$)'
		'(curl|wget|fetch)[^;&]*([;&]{1,2}|\|\|)[[:space:]]*(sudo[[:space:]]+)?((ba|z|k|da)?sh|source|\.)[[:space:]]'
		'((ba|z|k|da)?sh|source)[[:space:]]*<\([[:space:]]*(curl|wget|fetch)'
		'(^|[[:space:]])\.[[:space:]]*<\([[:space:]]*(curl|wget|fetch)'
		'(eval|exec)[^)]{0,20}\$\([[:space:]]*(curl|wget|fetch)'
		'base64[[:space:]]+(-d|-D|--decode)[^|]*\|[[:space:]]*((ba|z|k|da)?sh|node|python[23]?|perl)([[:space:]]|$)'
		'(node|python[23]?|ruby|perl|php)[[:space:]]+-[ce].{0,160}(\beval\b|exec\(|child_process|os\.system|subprocess|urlopen|Function\(|atob\(|Buffer\.from\([^)]*base64)'
		'npx[[:space:]][^;]*https?://'
		'/dev/(tcp|udp)/'
		'\b(nc|ncat|netcat)[[:space:]]+([^[:space:]]+[[:space:]]+)*-[a-z]*e[a-z]*([[:space:]]|$)'
		'\bsocat[[:space:]].*(exec|system):'
		'reverse[[:space:]_-]?shell'
	)

	for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
		if matches "$pattern" "$scripts"; then
			echo "BLOCKED: Suspicious npm script detected in $file: pattern '$pattern'" >&2
			return 1
		fi
	done

	return 0
}

check_python_setup() {
	local file="$1"
	local content
	content=$(cat "$file" 2>/dev/null || echo "")

	if matches 'os\.system|subprocess\.(run|call|Popen)|exec\(|eval\(|__import__.*os' "$content"; then
		echo '{"systemMessage": "Warning: Python setup file contains code execution patterns. Verify legitimacy before installing."}'
	fi

	return 0
}

# === MAIN CHECKS ===

for risk_file in "${HIGH_RISK_FILES[@]}"; do
	if [[ "$FILENAME" == "$risk_file" ]]; then
		check_injection_patterns "$FILE_PATH" || exit 2
		break
	fi
done

for config_file in "${CONFIG_FILES[@]}"; do
	if [[ "$FILENAME" == "$config_file" ]]; then
		case "$FILENAME" in
		package.json)
			check_package_json "$FILE_PATH" || exit 2
			;;
		pyproject.toml | setup.py | setup.cfg)
			# Warns via systemMessage and always returns 0; there is nothing to trap.
			check_python_setup "$FILE_PATH"
			;;
		Makefile)
			check_injection_patterns "$FILE_PATH" || exit 2
			;;
		esac
		break
	fi
done

# Check IDE config directories. A project's own .claude/ is in scope here — only
# $HOME/.claude, the user's own config, was exempted above.
for ide_pattern in "${IDE_CONFIG_PATTERNS[@]}"; do
	if [[ "$DIRNAME" == *"$ide_pattern"* || "$REAL_PATH" == *"$ide_pattern"* ]]; then
		check_injection_patterns "$REAL_PATH" || exit 2

		if [[ "$FILENAME" == *.json ]]; then
			# Collect the values of command-ish keys at any depth. The previous
			# form matched '"hooks".*"curl ' on the raw text, which only ever fired
			# on single-line JSON — every pretty-printed settings.json passed. The
			# path filter is what keeps `"Bash(curl *)"` under permissions.allow
			# from reading as a malicious hook.
			commands=$(jq -r '[paths(scalars) as $p | select(($p|map(tostring)|join("/")) | test("hook|command|script|run|exec|arg"; "i")) | (getpath($p)|tostring)] | join("\n")' "$REAL_PATH" 2>/dev/null || echo "")
			if matches '(curl|wget|fetch)[[:space:]]|\b(nc|ncat|netcat)[[:space:]]+-|/dev/(tcp|udp)/|base64[[:space:]]+(-d|--decode)|<\([[:space:]]*(curl|wget)|\$\([[:space:]]*(curl|wget)' "$commands"; then
				echo "BLOCKED: Suspicious hook command in IDE config: $FILE_PATH" >&2
				exit 2
			fi
		fi
		break
	fi
done

exit 0
