#!/usr/bin/env bash
# PreToolUse:Bash — Security gate for shell commands
# Blocks destructive commands, secret exposure, delimiter injection, and unicode attacks.
# Exit 0 = allow, Exit 2 = block
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(jq -r '.tool_name // empty' <<<"$INPUT")
TOOL_INPUT=$(jq -r '.tool_input // empty' <<<"$INPUT")

[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(jq -r '.command // empty' <<<"$TOOL_INPUT")
[[ -z "$COMMAND" ]] && exit 0

# ── Destructive commands ────────────────────────────────────────────────────

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

	if echo "$cmd" | grep -qE "git push.*(--force-with-lease|--force\b|-f\b)"; then
		echo "BLOCKED: Force push is forbidden (all branches)" >&2
		exit 2
	fi

	if echo "$cmd" | grep -qE "npm publish|pnpm publish|yarn publish"; then
		echo "BLOCKED: Package publication requires manual confirmation" >&2
		exit 2
	fi
}

# ── Secrets in commands ─────────────────────────────────────────────────────

check_secrets_in_command() {
	local cmd="$1"

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

# ── curl/wget exfiltration via file arguments ───────────────────────────────

check_curl_exfiltration() {
	local cmd="$1"

	echo "$cmd" | grep -qE '\b(curl|wget)\b' || return 0

	# @<sensitive-homedir> — curl reads file content and sends it
	if echo "$cmd" | grep -qiE '@(~|/home/[^/ ]+|/root)/?\.(ssh|aws|gnupg|netrc|claude)(/|[^/a-zA-Z]|$)'; then
		echo "BLOCKED: curl/wget exfiltration attempt via @file syntax (sensitive home dir)" >&2
		exit 2
	fi

	# @.env — relative path common in project roots
	if echo "$cmd" | grep -qiE '@\.env\b'; then
		echo "BLOCKED: curl/wget attempting to send .env file" >&2
		exit 2
	fi

	# -T / --upload-file <sensitive-path> (no @ needed)
	if echo "$cmd" | grep -qiE '(-T|--upload-file)[= ]+[^ ]*(\.ssh|\.aws|\.gnupg|id_rsa|id_ed25519|id_ecdsa|credentials)[^ ]*'; then
		echo "BLOCKED: curl upload (-T/--upload-file) targeting sensitive file" >&2
		exit 2
	fi

	# -d / --data* @<system-sensitive-file>
	if echo "$cmd" | grep -qiE '(-d|--data[^ ]*)[= ]+@[^ ]*(id_rsa|id_ed25519|id_ecdsa|/etc/passwd|/etc/shadow|/etc/sudoers)'; then
		echo "BLOCKED: curl --data targeting sensitive system file" >&2
		exit 2
	fi

	# wget --post-file <sensitive-path>
	if echo "$cmd" | grep -qiE -- '--post-file[= ]+[^ ]*(\.ssh|\.aws|\.gnupg|id_rsa|credentials|\.env)[^ ]*'; then
		echo "BLOCKED: wget --post-file targeting sensitive file" >&2
		exit 2
	fi
}

# ── Injection patterns (strong signals only) ────────────────────────────────

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
		"you are now"
		"new instructions:"
		"system prompt:"
	)
	for pattern in "${role_overrides[@]}"; do
		if [[ "$content_lower" == *"$pattern"* ]]; then
			echo "BLOCKED: Prompt injection detected - role override attempt: '$pattern'" >&2
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

	# Base64-encoded injection payloads
	if echo "$content" | grep -qE '[A-Za-z0-9+/]{50,}={0,2}'; then
		local decoded
		decoded=$(echo "$content" | grep -oE '[A-Za-z0-9+/]{50,}={0,2}' | head -1 | base64 -d 2>/dev/null || true)
		local decoded_lower
		decoded_lower=$(echo "$decoded" | tr '[:upper:]' '[:lower:]')
		for keyword in "ignore" "override" "system" "jailbreak"; do
			if [[ "$decoded_lower" == *"$keyword"* ]]; then
				echo "BLOCKED: Prompt injection detected - encoded payload containing: '$keyword'" >&2
				exit 2
			fi
		done
	fi

	# Nested dangerous commands in subshells
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
}

# ── Unicode attacks ─────────────────────────────────────────────────────────

check_unicode_attacks() {
	local content="$1"

	if echo "$content" | grep -qP '[\x{200B}-\x{200D}\x{FEFF}]' 2>/dev/null; then
		echo "BLOCKED: Zero-width characters detected." >&2
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
}

# ── Main ────────────────────────────────────────────────────────────────────

check_destructive_commands "$COMMAND"
check_secrets_in_command "$COMMAND"
check_curl_exfiltration "$COMMAND"
check_injection_patterns "$COMMAND"
check_unicode_attacks "$COMMAND"

if echo "$COMMAND" | grep -qE "rm -r|rmdir|unlink"; then
	echo '{"systemMessage": "Warning: File deletion detected. Verify this is intentional."}'
fi

exit 0
