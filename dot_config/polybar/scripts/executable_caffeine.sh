#!/usr/bin/env bash

# Caffeine mode - prevents screen lock and sleep
# State file to track if caffeine is active
STATE_FILE="/tmp/caffeine-polybar.pid"

# Icons
ICON_ON=""  # Caffeine active
ICON_OFF=""  # Caffeine inactive

# Check if caffeine is currently active
is_active() {
    [[ -f "$STATE_FILE" ]] && kill -0 $(cat "$STATE_FILE" 2>/dev/null) 2>/dev/null
}

# Toggle caffeine mode
toggle() {
    if is_active; then
        # Turn off caffeine
        kill $(cat "$STATE_FILE" 2>/dev/null) 2>/dev/null
        rm -f "$STATE_FILE"
        # Re-enable DPMS
        xset +dpms
        xset s on
    else
        # Turn on caffeine - prevent sleep and screen off
        systemd-inhibit --what=idle:sleep:handle-lid-switch \
                       --who="Polybar Caffeine" \
                       --why="User requested to prevent sleep" \
                       sleep infinity &
        echo $! > "$STATE_FILE"
        # Disable DPMS
        xset -dpms
        xset s off
    fi
}

# Display current status
status() {
    if is_active; then
        echo "$ICON_ON"
    else
        echo "$ICON_OFF"
    fi
}

# Main
case "${1:-status}" in
    toggle)
        toggle
        ;;
    status)
        status
        ;;
esac
