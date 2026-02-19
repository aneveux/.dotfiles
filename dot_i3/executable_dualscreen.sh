#!/usr/bin/env bash
set -euo pipefail

xrandr_output=$(xrandr)

# Detect first connected DP output
dp_name=$(echo "$xrandr_output" | grep -oP '^DP-\d+(?= connected)' | head -1 || true)

if [[ -z "$dp_name" ]]; then
  echo "No DP monitor connected"
  exit 1
fi

xrandr \
  --output "$dp_name" --mode 3840x2400 --rate 59.95 --pos 0x0 \
  --output eDP-1 --primary --mode 1920x1200 --rate 59.95 --pos 3840x0

sleep 1
i3-msg restart
