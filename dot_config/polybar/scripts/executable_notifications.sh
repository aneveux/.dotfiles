#!/usr/bin/env bash

# Notification toggle - enables/disables notification popups
# State file to track if notifications are paused
STATE_FILE="/tmp/notifications-polybar.state"

# Icons
ICON_ON=""  # Notifications enabled
ICON_OFF=""  # Notifications disabled

# Detect which notification daemon is running
detect_daemon() {
    if pgrep -x dunst > /dev/null; then
        echo "dunst"
    elif pgrep -x mako > /dev/null; then
        echo "mako"
    else
        echo "unknown"
    fi
}

# Check if notifications are currently paused
is_paused() {
    [[ -f "$STATE_FILE" ]] && [[ $(cat "$STATE_FILE") == "paused" ]]
}

# Toggle notification mode
toggle() {
    DAEMON=$(detect_daemon)

    if is_paused; then
        # Enable notifications
        case "$DAEMON" in
            dunst)
                dunstctl set-paused false
                ;;
            mako)
                makoctl mode -r dnd
                ;;
        esac
        rm -f "$STATE_FILE"
    else
        # Disable notifications
        case "$DAEMON" in
            dunst)
                dunstctl set-paused true
                ;;
            mako)
                makoctl mode -a dnd
                ;;
        esac
        echo "paused" > "$STATE_FILE"
    fi
}

# Display current status
status() {
    DAEMON=$(detect_daemon)

    # First check our state file
    if is_paused; then
        echo "$ICON_OFF"
        return
    fi

    # Then check daemon status
    case "$DAEMON" in
        dunst)
            if dunstctl is-paused | grep -q "true"; then
                echo "paused" > "$STATE_FILE"
                echo "$ICON_OFF"
            else
                echo "$ICON_ON"
            fi
            ;;
        mako)
            if makoctl mode | grep -q "dnd"; then
                echo "paused" > "$STATE_FILE"
                echo "$ICON_OFF"
            else
                echo "$ICON_ON"
            fi
            ;;
        *)
            echo "$ICON_ON"
            ;;
    esac
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
