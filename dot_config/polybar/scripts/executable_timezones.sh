#!/bin/bash

# Timezone display script for Polybar
# Shows current time in multiple timezones using rofi

# Define timezones and city names
declare -A timezones=(
    ["San Francisco"]="America/Los_Angeles"
    ["Raleigh"]="America/New_York"
    ["London"]="Europe/London"
    ["Bengaluru"]="Asia/Kolkata"
    ["Sydney"]="Australia/Sydney"
)

# Build the display message
message=""
max_city_length=0

# First pass: find the longest city name for alignment
for city in "${!timezones[@]}"; do
    if [ ${#city} -gt $max_city_length ]; then
        max_city_length=${#city}
    fi
done

# Second pass: format each timezone with proper alignment
for city in "San Francisco" "Raleigh" "London" "Bengaluru" "Sydney"; do
    tz="${timezones[$city]}"
    time=$(TZ="$tz" date "+%H:%M %Z")

    # Right-pad city name for alignment
    padded_city=$(printf "%-${max_city_length}s" "$city")

    message+="$padded_city  $time\n"
done

# Remove trailing newline
message=${message%\\n}

# Display with rofi
echo -e "$message" | rofi -dmenu -p "World Clocks" -theme-str 'window {width: 400px;} listview {lines: 5;}'
