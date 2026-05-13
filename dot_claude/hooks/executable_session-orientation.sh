#!/bin/bash
# Hook: SessionStart:startup — Project orientation context
# Provides Claude with immediate awareness of git state and stash items.
# Exit 0 = allow (always)

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
CWD="${CWD:-$(pwd)}"

if ! git -C "$CWD" rev-parse --is-inside-work-tree &>/dev/null; then
	exit 0
fi

BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || echo "detached")
COMMITS=$(git -C "$CWD" log --oneline -3 2>/dev/null | sed 's/"/\\"/g' | paste -sd '|' -)
DIRTY=$(git -C "$CWD" status --short 2>/dev/null | wc -l | tr -dc '0-9')

MSG="Branch: ${BRANCH}"
if [[ -n "$COMMITS" ]]; then
	MSG+=" | Recent: ${COMMITS}"
fi
if [[ "$DIRTY" -gt 0 ]]; then
	MSG+=" | Dirty: ${DIRTY} files"
fi

if [[ -f "$CWD/STASH.md" ]]; then
	OPEN=$(/usr/bin/grep -c '^\- \[ \]' "$CWD/STASH.md" 2>/dev/null || echo 0)
	if [[ "$OPEN" -gt 0 ]]; then
		MSG+=" | STASH: ${OPEN} open items"
	fi
fi

MSG="${MSG:0:500}"

jq -nc --arg msg "$MSG" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $msg
  }
}'
