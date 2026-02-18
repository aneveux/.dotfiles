#!/bin/bash

xrandr_output=$(xrandr)
dp_name=$(echo "$xrandr_output" | grep -oP '^DP-\d+(?= connected)' | head -1)

if [[ -z "$dp_name" ]]; then
    exit 0
fi

dp_line=$(echo "$xrandr_output" | grep "^${dp_name} ")

if echo "$dp_line" | grep -q "connected [0-9]"; then
    # Laptop only
    xrandr --output "$dp_name" --off \
           --output eDP-1 --primary --mode 1920x1200 --rate 59.95 --pos 0x0 --scale 1x1
else
    # Dual setup without floating rounding errors
    xrandr --output "$dp_name" --mode 3840x2160 --rate 60 --pos 0x0 --scale-from 2560x1440 \
           --output eDP-1 --primary --mode 1920x1200 --rate 59.95 --pos 2560x0 --scale 1x1
fi

sleep 1
i3-msg restart

