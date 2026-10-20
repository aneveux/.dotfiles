#!/usr/bin/env bash
# Toggles the ghostty dropdown, spawning it on first use or after it was closed.
set -euo pipefail

readonly instance=ghostty-scratch

if i3-msg -t get_tree | jq -e --arg instance "$instance" \
	'[.. | objects | select(.window_properties?.instance == $instance)] | length > 0' >/dev/null; then
	i3-msg -q "[instance=\"$instance\"] scratchpad show"
else
	setsid -f ghostty --x11-instance-name="$instance" >/dev/null 2>&1
fi
