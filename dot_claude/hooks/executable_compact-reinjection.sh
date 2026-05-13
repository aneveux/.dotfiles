#!/bin/bash
# Hook: SessionStart:compact — Re-inject session state after compaction
# Reads state snapshot saved by pre-compact-snapshot.sh
# Exit 0 = allow (always)

set -euo pipefail

SESSION_ID="${CLAUDE_SESSION_ID:-}"

if [[ -z "$SESSION_ID" ]]; then
	exit 0
fi

STATE_DIR="$HOME/.claude/session-env/$SESSION_ID"

if [[ ! -d "$STATE_DIR" ]]; then
	exit 0
fi

MSG=""

if [[ -s "$STATE_DIR/files-modified.txt" ]]; then
	FILES=$(head -10 "$STATE_DIR/files-modified.txt" | tr '\n' ', ' | sed 's/,$//')
	MSG+="Files modified this session: ${FILES}\n"
fi

if [[ -s "$STATE_DIR/tests-run.txt" ]]; then
	TESTS=$(head -5 "$STATE_DIR/tests-run.txt" | tr '\n' ', ' | sed 's/,$//')
	MSG+="Tests run: ${TESTS}\n"
fi

if [[ -s "$STATE_DIR/git-state.txt" ]]; then
	GIT=$(cat "$STATE_DIR/git-state.txt")
	MSG+="Git state:\n${GIT}\n"
fi

if [[ -z "$MSG" ]]; then
	exit 0
fi

MSG="${MSG:0:1500}"

jq -nc --arg msg "$(printf '%b' "$MSG")" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $msg
  }
}'
