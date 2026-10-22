#!/usr/bin/env bash
# Polybar DND toggle. Pause level 60 holds normal notifications; dunst rules
# with a higher override_pause_level (battery) still get through.
set -euo pipefail

readonly ICON_ON=""
readonly ICON_OFF=""
readonly DND_LEVEL=60

is_paused() {
	[[ "$(dunstctl get-pause-level)" -gt 0 ]]
}

toggle() {
	if is_paused; then
		dunstctl set-pause-level 0
	else
		dunstctl set-pause-level "$DND_LEVEL"
	fi
}

status() {
	if ! pgrep -x dunst >/dev/null; then
		echo "$ICON_ON"
		return
	fi
	if ! is_paused; then
		echo "$ICON_ON"
		return
	fi
	local waiting
	waiting="$(dunstctl count waiting)"
	if [[ "$waiting" -gt 0 ]]; then
		echo "$ICON_OFF $waiting"
	else
		echo "$ICON_OFF"
	fi
}

case "${1:-status}" in
toggle) toggle ;;
status) status ;;
*) exit 1 ;;
esac
