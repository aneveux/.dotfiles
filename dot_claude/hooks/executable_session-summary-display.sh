#!/bin/bash
# Hook: Stop — Flush any pending session summary written by SessionEnd hook.
# SessionEnd runs without a terminal since Claude Code v2.1.139, so session-summary.sh
# writes its output to a tmp file. This hook picks it up on the first Stop after exit.

PENDING_DIR="${TMPDIR:-/tmp}/claude-session-summary"

[[ -d "$PENDING_DIR" ]] || exit 0

shopt -s nullglob
files=("$PENDING_DIR"/*.pending)
[[ ${#files[@]} -eq 0 ]] && exit 0

for f in "${files[@]}"; do
	cat "$f" >/dev/tty 2>/dev/null || cat "$f" >&2
	rm -f "$f"
done
