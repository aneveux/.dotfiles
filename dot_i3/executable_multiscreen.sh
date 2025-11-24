#!/bin/bash

# Get all connected monitors
mapfile -t monitors < <(xrandr --query | grep " connected" | cut -d" " -f1)

# Initialize variables
laptop_screen=""
main_screen=""
vertical_screen=""

# Classify monitors
for monitor in "${monitors[@]}"; do
    if [[ "$monitor" =~ ^eDP ]]; then
        laptop_screen="$monitor"
    else
        # Get the monitor's preferred resolution
        resolution=$(xrandr --query | grep -A1 "^$monitor connected" | tail -n1 | awk '{print $1}')
        width=$(echo "$resolution" | cut -d'x' -f1)
        height=$(echo "$resolution" | cut -d'x' -f2)

        # Main screen has width > 3000px
        if [[ $width -gt 3000 ]]; then
            main_screen="$monitor"
            main_resolution="$resolution"
            main_width="$width"
        # Vertical screen: height > width (will be rotated)
        elif [[ -z "$vertical_screen" ]]; then
            vertical_screen="$monitor"
            vertical_resolution="$resolution"
            # When rotated left, width becomes height
            vertical_width="$height"
        fi
    fi
done

# Build xrandr command dynamically
cmd="xrandr"
x_pos=0

# 1. Vertical screen on the left (if exists)
if [[ -n "$vertical_screen" ]]; then
    cmd+=" --output $vertical_screen --mode $vertical_resolution --rate 60 --pos ${x_pos}x0 --rotate left"
    x_pos=$((x_pos + vertical_width))
fi

# 2. Main screen in the middle (if exists)
if [[ -n "$main_screen" ]]; then
    cmd+=" --output $main_screen --primary --mode $main_resolution --rate 60 --pos ${x_pos}x0 --rotate normal"
    x_pos=$((x_pos + main_width))
fi

# 3. Laptop screen on the right (if exists)
if [[ -n "$laptop_screen" ]]; then
    laptop_resolution=$(xrandr --query | grep -A1 "^$laptop_screen connected" | tail -n1 | awk '{print $1}')
    cmd+=" --output $laptop_screen --mode $laptop_resolution --rate 60 --pos ${x_pos}x0 --rotate normal"
fi

# Turn off any other monitors not configured
for monitor in "${monitors[@]}"; do
    if [[ "$monitor" != "$laptop_screen" && "$monitor" != "$main_screen" && "$monitor" != "$vertical_screen" ]]; then
        cmd+=" --output $monitor --off"
    fi
done

# Execute the command
echo "Executing: $cmd"
eval "$cmd"
