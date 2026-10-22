#!/usr/bin/env bash
# rofi calculator on top of qalc, bound to $mod+c in ~/.i3/config.
# Enter evaluates the input; Enter on an empty input copies the last result.
set -euo pipefail

readonly theme_str='window { width: 600px; height: 140px; } listview { enabled: false; }'

escape_markup() {
	printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

prompt() {
	rofi -dmenu -p calc -mesg "$1" -theme-str "$theme_str" </dev/null
}

main() {
	local message="Enter evaluates, Enter on empty input copies the result"
	local result="" input
	while true; do
		input="$(prompt "$message")" || exit 0
		if [[ -z "$input" ]]; then
			[[ -n "$result" ]] && printf '%s' "$result" | xclip -selection clipboard
			exit 0
		fi
		result="$(qalc -s 'decimal comma off' -s 'unicode off' -t -- "$input" 2>&1 </dev/null)"
		message="$(escape_markup "$input = $result")"
	done
}

main
