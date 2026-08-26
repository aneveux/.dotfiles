#!/usr/bin/env bash
set -euo pipefail

# ConfigChange(user_settings) — block unauthorized edits to ~/.claude/settings.json
# Exit 2 = block (rollback contract unverified as of 2.1.246, but observed behavior)

FLOOR=41 # Expected deny-rule count after Wave 2

COUNT=$(jq '.permissions.deny | length' "$HOME/.claude/settings.json" 2>/dev/null || echo 0)

if ((COUNT < FLOOR)); then
	echo "[config-guard] BLOCKED: settings.json deny count dropped to $COUNT (floor: $FLOOR)" >&2
	echo "[config-guard] Likely cause: attempt to delete control-surface deny rules" >&2
	exit 2
fi

exit 0
