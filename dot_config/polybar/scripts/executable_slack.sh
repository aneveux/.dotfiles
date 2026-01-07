#!/usr/bin/env bash

# Get Slack highlighted messages count (mentions/DMs)
SLACK_STATE="$HOME/snap/slack/current/.config/Slack/storage/root-state.json"

if [[ -f "$SLACK_STATE" ]]; then
    highlights=$(jq -r '.webapp.teams[].unreads.unreadHighlights // 0' "$SLACK_STATE" 2>/dev/null | awk '{s+=$1} END {print s}')
    echo "${highlights:-0}"
else
    echo "0"
fi
