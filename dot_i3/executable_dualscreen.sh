#!/usr/bin/env bash
set -euo pipefail

# Force re-probe all DP outputs (i915 often has stale link state)
for dp in $(xrandr | grep -oP '^DP-\d+'); do
  xrandr --output "$dp" --auto 2>/dev/null || true
done

sleep 1

dp_name=$(xrandr | grep -oP '^DP-\d+(?= connected)' | head -1 || true)

if [[ -z "$dp_name" ]]; then
  echo "No DP monitor detected after re-probe"
  exit 1
fi

xrandr \
  --output "$dp_name" --mode 3840x2400 --rate 59.99 --pos 0x0 \
  --output eDP-1 --primary --mode 1920x1200 --rate 59.95 --pos 3840x0

sleep 1
i3-msg restart
