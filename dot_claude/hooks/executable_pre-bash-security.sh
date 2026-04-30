#!/usr/bin/env bash
# Consolidated PreToolUse security hook
# Merges: security-check.sh, dangerous-actions-blocker.sh,
#         prompt-injection-detector.sh, unicode-injection-detector.sh
# Run on: Bash, Write, Edit (via matcher)
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(jq -r '.tool_name // empty' <<< "$INPUT")
TOOL_INPUT=$(jq -r '.tool_input // empty' <<< "$INPUT")

check_destructive_commands() {
	local cmd="$1"

	local -a destructive=(
		"rm -rf /"
		"rm -rf ~"
		"rm -rf ~/"
		'rm -rf $HOME'
		"dd if="
		"mkfs"
		':(){:|:&};:'
		"> /dev/sda"
		"chmod -R 777 /"
		"chown -R"
		"sudo rm"
		"DROP DATABASE"
		"DROP TABLE"
		"--no-preserve-root"
	)

	for pattern in "${destructive[@]}"; do
		if [[ "$cmd" == *"$pattern"* ]]; then
			echo "BLOCKED: Dangerous command detected: '$pattern'" >&2
			exit 2
		fi
	done

	if echo "$cmd" | grep -qE "git push.*(-f|--force).*(main|master)"; then
		echo "BLOCKED: Force push to main/master is forbidden" >&2
		exit 2
	fi

	if echo "$cmd" | grep -qE "npm publish|pnpm publish|yarn publish"; then
		echo "BLOCKED: Package publication requires manual confirmation" >&2
		exit 2
	fi
}

check_secrets_in_command() {
	local cmd="$1"

	# Strip quoted strings to avoid false positives on echo/printf/heredoc content
	local stripped
	stripped=$(echo "$cmd" | sed -E \
		-e 's/"[^"]*"//g' \
		-e "s/'[^']*'//g" \
		-e 's/`[^`]*`//g')

	local -a secret_patterns=(
		"[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]="
		"[Ss][Ee][Cc][Rr][Ee][Tt]="
		"[Aa][Pp][Ii][_-][Kk][Ee][Yy]="
		"[Aa][Pp][Ii][Kk][Ee][Yy]="
		"[Tt][Oo][Kk][Ee][Nn]="
		"[Aa][Ww][Ss]_[Aa][Cc][Cc][Ee][Ss][Ss]_[Kk][Ee][Yy]"
		"[Aa][Ww][Ss]_[Ss][Ee][Cc][Rr][Ee][Tt]"
		"[Pp][Rr][Ii][Vv][Aa][Tt][Ee]_[Kk][Ee][Yy]"
	)

	for pattern in "${secret_patterns[@]}"; do
		if echo "$stripped" | grep -qE "$pattern"; then
			echo '{"decision": "block", "reason": "Potential secret detected in command"}' >&2
			exit 2
		fi
	done

	if echo "$stripped" | grep -qE "(sk-[a-zA-Z0-9]{20,}|pk_[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16})"; then
		echo '{"decision": "block", "reason": "Potential API key or credential detected"}' >&2
		exit 2
	fi
}

check_injection_patterns() {
	local content="$1"
	local content_lower
	content_lower=$(echo "$content" | tr '[:upper:]' '[:lower:]')

	local -a role_overrides=(
		"ignore previous instructions"
		"ignore all previous"
		"ignore your instructions"
		"disregard previous"
		"disregard your instructions"
		"forget your instructions"
		"forget everything"
		"you are now"
		"act as if"
		"pretend you are"
		"pretend to be"
		"from now on you"
		"new instructions:"
		"override:"
		"system prompt:"
	)
	for pattern in "${role_overrides[@]}"; do
		if [[ "$content_lower" == *"$pattern"* ]]; then
			echo "BLOCKED: Prompt injection detected - role override attempt: '$pattern'" >&2
			exit 2
		fi
	done

	local -a jailbreaks=(
		"dan mode"
		"developer mode"
		"jailbreak"
		"do anything now"
		"bypass"
		"no restrictions"
		"without restrictions"
		"unrestricted mode"
		"god mode"
		"sudo mode"
		"admin mode"
		"debug mode"
		"maintenance mode"
	)
	for pattern in "${jailbreaks[@]}"; do
		if [[ "$content_lower" == *"$pattern"* ]]; then
			echo "BLOCKED: Prompt injection detected - jailbreak attempt: '$pattern'" >&2
			exit 2
		fi
	done

	local -a delimiters=(
		"</system>"
		"<|endoftext|>"
		"<|im_end|>"
		"[/INST]"
		"[INST]"
		"<<SYS>>"
		"<</SYS>>"
		"### System:"
		"### Human:"
		"### Assistant:"
		'```system'
		"SYSTEM:"
	)
	for pattern in "${delimiters[@]}"; do
		if [[ "$content" == *"$pattern"* ]]; then
			echo "BLOCKED: Prompt injection detected - delimiter injection: '$pattern'" >&2
			exit 2
		fi
	done

	local -a authorities=(
		"anthropic employee"
		"anthropic staff"
		"i am your creator"
		"i am your developer"
		"i have admin access"
		"authorized to bypass"
		"emergency override"
		"security exception"
		"this is a test"
		"testing mode"
	)
	for pattern in "${authorities[@]}"; do
		if [[ "$content_lower" == *"$pattern"* ]]; then
			echo "BLOCKED: Prompt injection detected - authority impersonation: '$pattern'" >&2
			exit 2
		fi
	done

	if echo "$content" | grep -qE '[A-Za-z0-9+/]{50,}={0,2}'; then
		local decoded
		decoded=$(echo "$content" | grep -oE '[A-Za-z0-9+/]{50,}={0,2}' | head -1 | base64 -d 2>/dev/null || true)
		local decoded_lower
		decoded_lower=$(echo "$decoded" | tr '[:upper:]' '[:lower:]')
		for keyword in "ignore" "override" "system" "jailbreak" "dan mode"; do
			if [[ "$decoded_lower" == *"$keyword"* ]]; then
				echo "BLOCKED: Prompt injection detected - encoded payload containing: '$keyword'" >&2
				exit 2
			fi
		done
	fi

	# Nested dangerous commands inside $() or backticks
	local -a nested_patterns=(
		'\$\([^)]*\b(curl|wget|bash|sh|nc|python|ruby|perl|php)\b'
		'\$\([^)]*\b(rm|dd|mkfs|chmod|chown)\b'
		'`[^`]*\b(curl|wget|bash|sh|nc|python|ruby|perl|php)\b'
		'`[^`]*\b(rm|dd|mkfs|chmod|chown)\b'
	)
	for pattern in "${nested_patterns[@]}"; do
		if echo "$content" | grep -qE "$pattern"; then
			echo "BLOCKED: Nested command execution detected - potential bypass attempt" >&2
			exit 2
		fi
	done

	local -a context_manip=(
		"in the previous message"
		"as i mentioned earlier"
		"you agreed to"
		"you already said"
		"you promised"
		"remember when you"
		"our agreement was"
	)
	for pattern in "${context_manip[@]}"; do
		if [[ "$content_lower" == *"$pattern"* ]]; then
			echo '{"systemMessage": "Warning: Detected potential context manipulation pattern. Verify legitimacy."}'
			break
		fi
	done
}

check_unicode_attacks() {
	local content="$1"

	if echo "$content" | grep -qP '[\x{200B}-\x{200D}\x{FEFF}]' 2>/dev/null; then
		echo "BLOCKED: Zero-width characters detected (U+200B-U+200D or BOM)." >&2
		exit 2
	fi

	if echo "$content" | grep -qP '[\x{202A}-\x{202E}\x{2066}-\x{2069}]' 2>/dev/null; then
		echo "BLOCKED: Bidirectional text override detected." >&2
		exit 2
	fi

	if echo "$content" | grep -qE $'\x1b\[|\x1b\]|\x1b\(' 2>/dev/null; then
		echo "BLOCKED: ANSI escape sequence detected." >&2
		exit 2
	fi

	if echo "$content" | grep -qP '\x00' 2>/dev/null; then
		echo "BLOCKED: Null byte detected." >&2
		exit 2
	fi

	if echo "$content" | grep -qP '[\x{E0000}-\x{E007F}]' 2>/dev/null; then
		echo "BLOCKED: Unicode tag characters detected." >&2
		exit 2
	fi

	if echo "$content" | grep -qP '[\xC0-\xC1][\x80-\xBF]' 2>/dev/null; then
		echo "BLOCKED: Overlong UTF-8 sequence detected." >&2
		exit 2
	fi

	local homoglyphs=false
	if echo "$content" | grep -qP '[\x{0430}\x{0435}\x{043E}\x{0440}\x{0441}\x{0445}]' 2>/dev/null; then
		homoglyphs=true
	fi
	if echo "$content" | grep -qP '[\x{0391}-\x{03C9}]' 2>/dev/null && echo "$content" | grep -qP '[a-zA-Z]' 2>/dev/null; then
		homoglyphs=true
	fi
	if [[ "$homoglyphs" == "true" ]]; then
		echo '{"systemMessage": "Warning: Potential homoglyph characters detected (Cyrillic/Greek mixed with Latin)."}'
	fi
}

check_write_edit() {
	local file_path
	file_path=$(jq -r '.file_path // empty' <<< "$TOOL_INPUT")

	local filename
	filename=$(basename "$file_path")
	local -a protected=(
		".env" ".env.local" ".env.production" ".env.development"
		"credentials.json" "serviceAccountKey.json"
		"id_rsa" "id_ed25519" "id_ecdsa"
		".npmrc" ".pypirc" "secrets.yml" "secrets.yaml"
	)
	for pf in "${protected[@]}"; do
		if [[ "$filename" == "$pf" ]]; then
			echo "BLOCKED: Editing sensitive file '$filename' is forbidden" >&2
			exit 2
		fi
	done

	local project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
	local claude_home="$HOME/.claude"
	local extra="${ALLOWED_PATHS:-}"
	local allowed=false

	[[ "$file_path" == "$project_dir"* ]] && allowed=true
	[[ "$file_path" == "$claude_home"* ]] && allowed=true
	[[ "$file_path" == "/tmp"* ]] && allowed=true

	if [[ -n "$extra" ]]; then
		IFS=':' read -ra extra_paths <<< "$extra"
		for ap in "${extra_paths[@]}"; do
			[[ "$file_path" == "$ap"* ]] && allowed=true
		done
	fi

	if [[ "$allowed" == "false" ]]; then
		echo "BLOCKED: Editing outside project is forbidden: $file_path" >&2
		echo "Allowed paths: $project_dir, $claude_home, /tmp" >&2
		[[ -n "$extra" ]] && echo "Additional allowed: $extra" >&2
		exit 2
	fi

	local content=""
	if [[ "$TOOL_NAME" == "Write" ]]; then
		content=$(jq -r '.content // empty' <<< "$TOOL_INPUT")
	else
		content=$(jq -r '.new_string // empty' <<< "$TOOL_INPUT")
	fi
	[[ -n "$content" ]] && check_unicode_attacks "$content"
}

# Main dispatch
case "$TOOL_NAME" in
Bash)
	COMMAND=$(jq -r '.command // empty' <<< "$TOOL_INPUT")
	[[ -z "$COMMAND" ]] && exit 0
	check_destructive_commands "$COMMAND"
	check_secrets_in_command "$COMMAND"
	check_injection_patterns "$COMMAND"
	check_unicode_attacks "$COMMAND"
	if echo "$COMMAND" | grep -qE "rm -r|rmdir|unlink"; then
		echo '{"systemMessage": "Warning: File deletion detected. Verify this is intentional."}'
	fi
	;;
Write | Edit)
	check_write_edit
	;;
WebFetch)
	URL=$(jq -r '.url // empty' <<< "$TOOL_INPUT")
	[[ -n "$URL" ]] && check_injection_patterns "$URL"
	;;
*)
	exit 0
	;;
esac

exit 0
