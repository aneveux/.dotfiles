#!/usr/bin/env bash
set -euo pipefail

# Get xrandr output
xrandr_output=$(xrandr)

# Detect first connected DP-* output
dp_name=$(echo "$xrandr_output" | grep -oP '^DP-\d+(?= connected)' | head -1)

# Exit if no external DP monitor is connected
if [[ -z "$dp_name" ]]; then
    exit 0
fi

dp_line=$(echo "$xrandr_output" | grep "^${dp_name} ")

if echo "$dp_line" | grep -q "connected [0-9]"; then
    # External monitor is active → switch to laptop only
    xrandr \
        --output "$dp_name" --off \
        --output eDP-1 --primary --mode 1920x1200 --rate 59.95 --pos 0x0
else
    # External monitor connected but inactive → enable dual display
    # Run external at native 2560x1440 for stability, no fractional scaling
    xrandr \
        --output "$dp_name" --mode 3840x2400 --rate 59.95 --pos 0x0 \
        --output eDP-1 --primary --mode 1920x1200 --rate 59.95 --pos 3840x0
fi

# Give X a moment to settle, then restart i3 to pick up new layout
sleep 1
i3-msg restart

