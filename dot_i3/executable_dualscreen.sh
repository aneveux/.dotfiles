#!/bin/bash

# Toggle dual monitor: 4K (DP-*, left, 1.5x scale) + laptop (eDP-1, right)

xrandr_output=$(xrandr)

# Find a connected DP-* output (covers DP-1, DP-2, DP-3, DP-4, etc.)
dp_name=$(echo "$xrandr_output" | grep -oP '^DP-\d+(?= connected)' | head -1)

if [[ -z "$dp_name" ]]; then
    echo "No external DP monitor connected."
    exit 0
fi

dp_line=$(echo "$xrandr_output" | grep "^${dp_name} ")

# When active, xrandr shows "DP-X connected 3840x2160+0+0 ..."
# When inactive, it shows "DP-X connected (normal left ..."
if echo "$dp_line" | grep -q "connected [0-9]"; then
    # External monitor is active → laptop only
    xrandr --output "$dp_name" --off \
           --output eDP-1 --primary --mode 1920x1200 --rate 60 --pos 0x0 --scale 1x1
else
    # External monitor connected but off → enable dual setup
    # 4K at 1.5x scale: 3840/1.5 x 2160/1.5 = 2560x1440 effective
    xrandr --output "$dp_name" --mode 3840x2160 --rate 60 --pos 0x0 --scale 0.6667x0.6667 \
           --output eDP-1 --primary --mode 1920x1200 --rate 60 --pos 2560x0 --scale 1x1
fi

sleep 2
i3-msg restart
