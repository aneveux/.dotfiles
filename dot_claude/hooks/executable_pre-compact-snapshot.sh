#!/bin/bash
# Hook: PreCompact — Snapshot session state before context compaction
# Harvests modified files and test commands from activity logs.
# Exit 0 = allow compaction (always)

set -euo pipefail

INPUT=$(cat)
SESSION_ID="${CLAUDE_SESSION_ID:-}"
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
CWD="${CWD:-$(pwd)}"

if [[ -z "$SESSION_ID" ]]; then
	exit 0
fi

STATE_DIR="$HOME/.claude/session-env/$SESSION_ID"
mkdir -p "$STATE_DIR"

TODAY=$(date +%Y-%m-%d)
LOG="$HOME/.claude/logs/activity-${TODAY}.jsonl"

if [[ ! -f "$LOG" ]]; then
	exit 0
fi

/usr/bin/grep "\"$SESSION_ID\"" "$LOG" | jq -r 'select(.tool == "Write" or .tool == "Edit") | .file // empty' |
	sort -u | head -20 >"$STATE_DIR/files-modified.txt" 2>/dev/null || true

/usr/bin/grep "\"$SESSION_ID\"" "$LOG" | jq -r 'select(.tool == "Bash") | .command // empty' |
	/usr/bin/grep -iE '(test|bats|spec|check|verify|pytest|vitest|jest)' |
	head -10 >"$STATE_DIR/tests-run.txt" 2>/dev/null || true

git -C "$CWD" diff --stat HEAD 2>/dev/null | tail -5 >"$STATE_DIR/git-state.txt" || true
git -C "$CWD" log --oneline -3 2>/dev/null >>"$STATE_DIR/git-state.txt" || true

exit 0
