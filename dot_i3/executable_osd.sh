#!/usr/bin/env bash
# Volume and brightness keys with a dunst progress-bar OSD, bound in ~/.i3/config
set -euo pipefail

readonly volume_icon=$'\U000F057E'     # nf-md-volume_high
readonly mute_icon=$'\U000F075F'       # nf-md-volume_off
readonly brightness_icon=$'\U000F00E0' # nf-md-brightness_6
readonly volume_step=5
readonly brightness_step=10

usage() {
	echo "usage: ${0##*/} volume up|down|mute | brightness up|down" >&2
	exit 1
}

show() {
	local tag="$1" value="$2" label="$3"
	dunstify -a osd -u low -h "int:value:$value" -h "string:x-dunst-stack-tag:$tag" "$label"
}

volume() {
	case "$1" in
	up) pactl set-sink-volume @DEFAULT_SINK@ "+${volume_step}%" ;;
	down) pactl set-sink-volume @DEFAULT_SINK@ "-${volume_step}%" ;;
	mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
	*) usage ;;
	esac

	local level muted
	level="$(LC_ALL=C pactl get-sink-volume @DEFAULT_SINK@ | grep -oE '[0-9]+%' | head -1 | tr -d %)"
	muted="$(LC_ALL=C pactl get-sink-mute @DEFAULT_SINK@)"
	if [[ "$muted" == *yes ]]; then
		show volume 0 "$mute_icon muted"
	else
		show volume "$level" "$volume_icon ${level}%"
	fi
}

brightness() {
	case "$1" in
	up) brightnessctl -q set "+${brightness_step}%" ;;
	down) brightnessctl -q set "${brightness_step}%-" ;;
	*) usage ;;
	esac

	local level
	level="$(brightnessctl -m | cut -d, -f4 | tr -d %)"
	show brightness "$level" "$brightness_icon ${level}%"
}

[[ $# -eq 2 ]] || usage
case "$1" in
volume) volume "$2" ;;
brightness) brightness "$2" ;;
*) usage ;;
esac
