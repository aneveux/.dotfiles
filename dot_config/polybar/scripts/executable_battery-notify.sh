#!/usr/bin/env bash

# Battery Low Notification Script
# Sends desktop notifications at different battery levels

# Configuration
BATTERY="BAT0"
STATE_FILE="/tmp/battery-notify-state"

# Thresholds (percentage)
CRITICAL=5
LOW=10
WARNING=20

# Get current battery level and status
CAPACITY=$(cat /sys/class/power_supply/${BATTERY}/capacity)
STATUS=$(cat /sys/class/power_supply/${BATTERY}/status)

# Read previous notification state
if [[ -f "$STATE_FILE" ]]; then
    source "$STATE_FILE"
else
    NOTIFIED_CRITICAL=0
    NOTIFIED_LOW=0
    NOTIFIED_WARNING=0
fi

# Only notify if discharging
if [[ "$STATUS" == "Discharging" ]]; then

    if [[ $CAPACITY -le $CRITICAL && $NOTIFIED_CRITICAL -eq 0 ]]; then
        notify-send -u critical -i battery-caution \
            "Battery Critical: ${CAPACITY}%" \
            "System will suspend soon. Plug in charger immediately!"
        NOTIFIED_CRITICAL=1
        NOTIFIED_LOW=1
        NOTIFIED_WARNING=1

    elif [[ $CAPACITY -le $LOW && $NOTIFIED_LOW -eq 0 ]]; then
        notify-send -u critical -i battery-low \
            "Battery Low: ${CAPACITY}%" \
            "Please plug in your charger soon."
        NOTIFIED_LOW=1
        NOTIFIED_WARNING=1

    elif [[ $CAPACITY -le $WARNING && $NOTIFIED_WARNING -eq 0 ]]; then
        notify-send -u normal -i battery-low \
            "Battery Warning: ${CAPACITY}%" \
            "Battery is getting low."
        NOTIFIED_WARNING=1
    fi

else
    # Reset notification flags when charging or full
    NOTIFIED_CRITICAL=0
    NOTIFIED_LOW=0
    NOTIFIED_WARNING=0
fi

# Save state
cat > "$STATE_FILE" << EOF
NOTIFIED_CRITICAL=$NOTIFIED_CRITICAL
NOTIFIED_LOW=$NOTIFIED_LOW
NOTIFIED_WARNING=$NOTIFIED_WARNING
EOF
