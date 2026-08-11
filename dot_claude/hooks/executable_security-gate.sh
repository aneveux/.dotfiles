#!/bin/bash
# Hook: PreToolUse - Security Gate
# Blocks writes carrying a provider credential or an invisible-character payload.
# Deliberately narrow: only checks with no false-positive history. Heuristic
# pattern-matching (SQL interpolation, eval, innerHTML, weak hashes, traversal)
# was removed after it blocked legitimate code, and a gate that cries wolf gets
# ignored. Command-level safety is cc-safety-net's job; this covers file content.
#
# Exit 0 = allow, Exit 2 = block (stderr message shown to Claude)

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
	exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

EXTENSION="${FILE_PATH##*.}"
SOURCE_EXTENSIONS="js ts jsx tsx py go java kt kts rs rb php cs sh tf yaml yml json gradle xml properties scala sql toml"
is_source=false
for ext in $SOURCE_EXTENSIONS; do
	[[ "$EXTENSION" == "$ext" ]] && is_source=true && break
done

if [[ "$is_source" == "false" ]]; then
	exit 0
fi

if [[ "$TOOL_NAME" == "Write" ]]; then
	CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
else
	CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
fi

# ── Provider credentials ─────────────────────────────────────────────────────
if echo "$CONTENT" | grep -qE '(sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[A-Z0-9]{16}|xox[bps]-[a-zA-Z0-9\-]{20,})'; then
	echo "SECURITY-GATE: Provider API key pattern detected in $FILE_PATH" >&2
	echo "Move to .env and reference via environment variable." >&2
	exit 2
fi

# ── Invisible characters in source code ──────────────────────────────────────
if echo "$CONTENT" | grep -qP '[\x{200B}-\x{200D}\x{FEFF}]' 2>/dev/null; then
	echo "SECURITY-GATE: Zero-width characters detected in $FILE_PATH" >&2
	echo "These can hide malicious content. Remove zero-width chars." >&2
	exit 2
fi

if echo "$CONTENT" | grep -qP '[\x{202A}-\x{202E}\x{2066}-\x{2069}]' 2>/dev/null; then
	echo "SECURITY-GATE: Bidirectional text override detected in $FILE_PATH" >&2
	echo "Bidi overrides can disguise malicious code (CVE-2021-42574)." >&2
	exit 2
fi

if echo "$CONTENT" | grep -qE $'\x1b\[|\x1b\]|\x1b\(' 2>/dev/null; then
	echo "SECURITY-GATE: ANSI escape sequence detected in $FILE_PATH" >&2
	echo "Escape sequences don't belong in source files." >&2
	exit 2
fi

if echo "$CONTENT" | grep -qP '\x00' 2>/dev/null; then
	echo "SECURITY-GATE: Null byte detected in $FILE_PATH" >&2
	exit 2
fi

exit 0
