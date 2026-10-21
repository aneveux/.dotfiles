#!/bin/sh
# Toggles stalonetray and the tray icon on the main bar (the only bar with module/tray).

hidden_flag="${XDG_RUNTIME_DIR:-/tmp}/polybar-tray.hidden"
main_bar_pid_file="${XDG_RUNTIME_DIR:-/tmp}/polybar-main.pid"

notify_main_bar() {
    [ -r "$main_bar_pid_file" ] || return 0
    polybar-msg -p "$(cat "$main_bar_pid_file")" action "#tray.hook.$1" >/dev/null
}

if pgrep -u "$(id -u)" -x stalonetray >/dev/null; then
    pkill -u "$(id -u)" -x stalonetray
    touch "$hidden_flag"
    notify_main_bar 1
else
    rm -f "$hidden_flag"
    stalonetray -c "$HOME/.config/polybar/stalonetrayrc" >/dev/null 2>&1 &
    notify_main_bar 0
fi
