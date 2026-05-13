#!/usr/bin/env bash
# Hook: CwdChanged — Detect worktree switches and set environment variables
# Reads new cwd from stdin, detects if in linked worktree, sets SAFETY_NET_WORKTREE=1
# Exit 0 = allow (always)

set -euo pipefail

INPUT=$(cat)
NEW_CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)

if [[ -z "$NEW_CWD" ]]; then
	exit 0
fi

GIT_FILE="$NEW_CWD/.git"

if [[ -f "$GIT_FILE" ]] && grep -q "^gitdir:" "$GIT_FILE" 2>/dev/null; then
	if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
		echo "SAFETY_NET_WORKTREE=1" >>"$CLAUDE_ENV_FILE"
	fi
fi

exit 0
