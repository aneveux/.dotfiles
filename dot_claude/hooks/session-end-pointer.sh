#!/bin/bash
# Hook: SessionEnd(clear) — write predecessor pointer for session-handover.sh
# Fired when the user runs /clear. Writes a ~100-byte pointer so session-handover.sh
# can find this transcript deterministically on the next SessionStart.
# Exit 0 always; SessionEnd cannot block.

set -euo pipefail

INPUT=$(cat)
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
[[ -z "$SESSION_ID" ]] && exit 0

TP=$(/usr/bin/jq -r '.transcript_path // empty' <<<"$INPUT")
[[ -z "$TP" || ! -f "$TP" ]] && exit 0

SLUG=$(basename "$(dirname "$TP")")
POINTER_DIR="$HOME/.claude/session-env/by-project/$SLUG"
mkdir -p "$POINTER_DIR"

/usr/bin/jq -nc \
	--arg sid "$SESSION_ID" \
	--arg tp "$TP" \
	'{session_id: $sid, transcript_path: $tp}' \
	>"$POINTER_DIR/last-clear.json"
