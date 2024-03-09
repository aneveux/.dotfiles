#!/bin/bash

ROFI_JIRA_HISTORY_FILE="$HOME/.rofi_jira_history"
MAX_DISPLAYED_HISTORY_ITEMS=10

declare -A JIRA_URLS
JIRA_URLS=(
  ["CLOUDBEES"]="https://cloudbees.atlassian.net/browse/"
  ["OSS"]="https://issues.jenkins.io/browse/"
)

function read_history {
  if [ ! -f "$ROFI_JIRA_HISTORY_FILE" ]; then
    touch "$ROFI_JIRA_HISTORY_FILE"
  fi
  recent_issues=$(head -n "$MAX_DISPLAYED_HISTORY_ITEMS" "$ROFI_JIRA_HISTORY_FILE")
  for issue in $recent_issues; do
    echo "$issue"
  done
}

function historize {
  if [ ! -s "$ROFI_JIRA_HISTORY_FILE" ]; then
    echo "$1" >"$ROFI_JIRA_HISTORY_FILE"
  else
    sed -i "1i $1" "$ROFI_JIRA_HISTORY_FILE"
  fi
}

function cb_url {
  echo "${JIRA_URLS["CLOUDBEES"]}$1"
}

function oss_url {
  echo "${JIRA_URLS["OSS"]}$1"
}

function open_in_browser {
  echo "opening: $1"
  xdg-open "$1"
}

JIRA_ISSUE=$( (read_history) | rofi -dmenu -matching fuzzy -location 0 -p "🔎 ")

case "$JIRA_ISSUE" in
'')
  exit 0
  ;;
[0-9]*)
  echo "Found Jira issue number: $JIRA_ISSUE"
  JIRA_REFERENCE="BEE-$JIRA_ISSUE"
  historize "$JIRA_REFERENCE"
  open_in_browser "$(cb_url "$JIRA_REFERENCE")"
  exit 0
  ;;
JENKINS*)
  echo "Found OSS Jira issue: $JIRA_ISSUE"
  historize "$JIRA_ISSUE"
  open_in_browser "$(oss_url "$JIRA_ISSUE")"
  exit 0
  ;;
*)
  echo "Found CB Jira issue: $JIRA_ISSUE"
  historize "$JIRA_ISSUE"
  open_in_browser "$(cb_url "$JIRA_ISSUE")"
  exit 0
  ;;
esac
