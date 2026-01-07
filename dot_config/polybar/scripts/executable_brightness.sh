#!/usr/bin/env bash

# Brightness control script for Polybar
# Simple percentage display with scroll control

# Get current brightness percentage
get_brightness() {
    brightnessctl get | awk -v max="$(brightnessctl max)" '{printf "%.0f", ($1/max)*100}'
}

# Icons based on brightness level
get_icon() {
    local brightness=$1
    if [[ $brightness -ge 75 ]]; then
        echo ""
    elif [[ $brightness -ge 50 ]]; then
        echo ""
    elif [[ $brightness -ge 25 ]]; then
        echo ""
    else
        echo ""
    fi
}

# Main output
brightness=$(get_brightness)
icon=$(get_icon $brightness)
echo "${icon} ${brightness}%"
