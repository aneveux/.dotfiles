#!/bin/env bash

monitors=$(xrandr --query | grep " connected " | cut -d" " -f1)

for monitor in $monitors; do
  if [[ "$monitor" =~ ^eDP.* ]]; then
    xrandr --output "$monitor" --primary --mode 1920x1080 --rotate normal
  else
    xrandr --output "$monitor" --off
  fi
done
