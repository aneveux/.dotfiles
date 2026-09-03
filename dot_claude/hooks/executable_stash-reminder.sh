#!/bin/bash
# Hook: Stop — Remind about STASH.md open items (once per session)
# Exit 0 = allow (always)

set -euo pipefail

INPUT=$(cat)
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
if [[ -z "$SESSION_ID" ]]; then
	exit 0
fi
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
CWD="${CWD:-$(pwd)}"

ONCE_FILE="/tmp/claude-stash-shown-${SESSION_ID}"
if [[ -f "$ONCE_FILE" ]]; then
	exit 0
fi

STASH="$CWD/STASH.md"
if [[ ! -f "$STASH" ]]; then
	exit 0
fi

# `grep -c` prints 0 and exits 1 on no match, so `|| echo 0` made OPEN "0\n0".
OPEN=$(/usr/bin/grep -c '^\- \[ \]' "$STASH" 2>/dev/null) || OPEN=0
if [[ "$OPEN" -eq 0 ]]; then
	exit 0
fi

touch "$ONCE_FILE"

jq -nc --arg msg "This project has STASH.md with ${OPEN} open items. Run 'address stash' if the user wants to review them." '{
  systemMessage: $msg
}'
