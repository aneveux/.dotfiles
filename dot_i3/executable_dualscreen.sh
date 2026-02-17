#!/bin/bash

# Get current state of external monitor DP-3
if xrandr | grep "DP-3 connected" | grep -q "3840x2160"; then
    # External monitor is on → turn it off
    xrandr --output DP-3 --off --output eDP-1 --primary --mode 1920x1200 --rate 60
else
    # External monitor is off → turn it on (to the left of laptop)
    xrandr --output DP-3 --mode 3840x2160 --rate 60 --pos 0x0 --rotate normal \
           --output eDP-1 --primary --mode 1920x1200 --rate 60 --pos 3840x0
fi

i3-msg restart
