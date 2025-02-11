#!/bin/sh

cache="$HOME/.config/polybar/tray.lock"
config="$HOME/.config/polybar/modules.ini"

[ ! -d "$HOME/.config/polybar/" ] && mkdir -p "$HOME/.config/polybar/"

if [ "$(pgrep stalonetray)" ]; then
    if [ ! -e "$cache" ]; then
        polybar-msg action "#tray.hook.1"
        killall stalonetray
        touch "$cache"
        #sed -i 's/tray\ninitial=.*/tray\ninitial=2/g' "$config"
    fi
else
    polybar-msg action "#tray.hook.0"
    rm "$cache"
    stalonetray -display :0 -c "$HOME/.config/polybar/stalonetrayrc" &
    #sed -i 's/tray\ninitial=.*/tray\ninitial=1/g' "$config"
fi

