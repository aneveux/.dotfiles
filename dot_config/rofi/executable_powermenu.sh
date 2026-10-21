#!/usr/bin/env bash
# rofi power menu bound to $mod+Shift+e in ~/.i3/config
set -euo pipefail

readonly theme="$HOME/.config/rofi/themes/powermenu.rasi"
readonly lock=$'\U000F033E'     # nf-md-lock
readonly logout=$'\U000F0343'   # nf-md-logout
readonly suspend=$'\U000F04B2'  # nf-md-sleep
readonly reboot=$'\U000F0709'   # nf-md-restart
readonly shutdown=$'\U000F0425' # nf-md-power

menu() {
	rofi -dmenu -i -theme "$theme" -p "$1" || true
}

confirm() {
	[[ "$(printf '%s\n' yes no | rofi -dmenu -i -p "$1?" -theme-str 'window { width: 300px; } listview { lines: 2; }' || true)" == yes ]]
}

choice="$(printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" | menu power)"

case "$choice" in
"$lock") "$HOME/.i3/lock.sh" ;;
"$suspend") systemctl suspend ;;
"$logout") confirm logout && i3-msg -q exit ;;
"$reboot") confirm reboot && systemctl reboot ;;
"$shutdown") confirm shutdown && systemctl poweroff ;;
*) exit 0 ;;
esac
