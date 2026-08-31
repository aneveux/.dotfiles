#!/usr/bin/env bash
set -euo pipefail

# ConfigChange(user_settings) — block unauthorized edits to ~/.claude/settings.json
# Exit 2 = block (rollback contract unverified as of 2.1.246, but observed behavior)

FLOOR=41 # Expected deny-rule count after Wave 2
SETTINGS="$HOME/.claude/settings.json"

# No settings file means there are no deny rules to protect yet, so there is
# nothing to guard. `jq … || echo 0` used to report this as "count dropped to 0"
# and block, which is a false statement about a file that does not exist. The
# deletion path is still covered: recreating settings.json fires ConfigChange
# again, and a file without the rules is caught below.
[[ -f "$SETTINGS" ]] || exit 0

# Unreadable is not the same as empty. A malformed file, or a permissions.deny
# replaced by something that is not a list, must block rather than silently
# read as zero.
if ! COUNT=$(jq '.permissions.deny // [] | length' "$SETTINGS" 2>/dev/null) ||
	[[ ! $COUNT =~ ^[0-9]+$ ]]; then
	echo "[config-guard] BLOCKED: no deny-rule count readable from $SETTINGS" >&2
	echo "[config-guard] Likely cause: malformed settings, or permissions.deny is not a list" >&2
	exit 2
fi

if ((COUNT < FLOOR)); then
	echo "[config-guard] BLOCKED: settings.json deny count dropped to $COUNT (floor: $FLOOR)" >&2
	echo "[config-guard] Likely cause: attempt to delete control-surface deny rules" >&2
	exit 2
fi

exit 0
