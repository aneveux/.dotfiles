#!/usr/bin/env bash
set -euo pipefail

monitors=$(xrandr --query | grep " connected " | cut -d" " -f1)

for monitor in $monitors; do
  if [[ "$monitor" =~ ^eDP ]]; then
    xrandr --output "$monitor" --primary --mode 1920x1200 --rate 59.95 --pos 0x0
  else
    xrandr --output "$monitor" --off
  fi
done

sleep 1
i3-msg restart
