#!/bin/bash
# Repository Integrity Scanner Hook
# Event: PreToolUse:Read — scan files for injection vectors before processing
#
# Detects prompt injection attempts hidden in:
#   - README.md, SECURITY.md (hidden HTML comments with instructions)
#   - package.json (malicious scripts)
#   - .claude/, .cursor/ configs (tampered configurations)
#
# Exit codes:
#   0 = allow (safe or not a target file)
#   2 = block (injection detected)

set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

[[ "$TOOL_NAME" != "Read" ]] && exit 0

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# Whitelist: never scan own config/hooks directory
[[ "$FILE_PATH" == "$HOME/.claude/"* ]] && exit 0

FILENAME=$(basename "$FILE_PATH")
DIRNAME=$(dirname "$FILE_PATH")

# === HIGH-RISK FILES ===
HIGH_RISK_FILES=(
	"README.md"
	"readme.md"
	"SECURITY.md"
	"CONTRIBUTING.md"
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
)

check_injection_patterns() {
	local file="$1"
	local content
	content=$(cat "$file" 2>/dev/null || echo "")

	# Hidden HTML comments with instruction-like content (require verb + target)
	if echo "$content" | grep -qiE '<!--.*(ignore (previous|all|your) instructions|override (instructions|system|prompt)|execute (this|the following)|you are now a|new instructions:).*-->'; then
		echo "BLOCKED: Hidden HTML comment with injection instructions in: $file" >&2
		return 1
	fi

	# Explicit role override patterns (multi-word, not single common words)
	if echo "$content" | grep -qiE 'ignore (previous|all|your) instructions|disregard (previous|your) instructions|you are now|from now on you (are|will|must)|new instructions:'; then
		echo "BLOCKED: Prompt injection pattern detected in: $file" >&2
		return 1
	fi

	# Base64 in comments containing injection keywords
	if echo "$content" | grep -qE '(#|//|<!--).*[A-Za-z0-9+/]{40,}={0,2}'; then
		local encoded
		encoded=$(echo "$content" | grep -oE '[A-Za-z0-9+/]{40,}={0,2}' | head -1)
		local decoded
		decoded=$(echo "$encoded" | base64 -d 2>/dev/null || echo "")
		if echo "$decoded" | grep -qiE 'ignore|override|system|jailbreak'; then
			echo "BLOCKED: Base64-encoded injection detected in: $file" >&2
			return 1
		fi
	fi

	return 0
}

check_package_json() {
	local file="$1"

	local scripts
	scripts=$(jq -r '.scripts // {} | to_entries[] | "\(.key): \(.value)"' "$file" 2>/dev/null || echo "")

	# Only truly suspicious patterns (remote execution, reverse shells)
	SUSPICIOUS_PATTERNS=(
		"curl.*|.*bash"
		"wget.*|.*sh"
		"nc -"
		"reverse.*shell"
		"/dev/tcp/"
		"base64.*-d.*|.*bash"
	)

	for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
		if echo "$scripts" | grep -qiE "$pattern"; then
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

	if echo "$content" | grep -qiE 'os\.system|subprocess\.(run|call|Popen)|exec\(|eval\(|__import__.*os'; then
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
			check_python_setup "$FILE_PATH" || exit 2
			;;
		Makefile)
			check_injection_patterns "$FILE_PATH" || exit 2
			;;
		esac
		break
	fi
done

# Check IDE config directories (not .claude — whitelisted above)
for ide_pattern in "${IDE_CONFIG_PATTERNS[@]}"; do
	if [[ "$DIRNAME" == *"$ide_pattern"* || "$FILE_PATH" == *"$ide_pattern"* ]]; then
		check_injection_patterns "$FILE_PATH" || exit 2

		if [[ "$FILENAME" == *.json ]]; then
			content=$(cat "$FILE_PATH" 2>/dev/null || echo "")
			# Only flag hooks referencing remote execution
			if echo "$content" | grep -qiE '"hooks".*"(curl\s|wget\s|nc\s+-|/dev/tcp)'; then
				echo "BLOCKED: Suspicious hook command in IDE config: $FILE_PATH" >&2
				exit 2
			fi
		fi
		break
	fi
done

exit 0
