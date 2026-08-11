#!/bin/bash
# Hook: SessionStart (all sources) — reinject prior-session context after compaction or /clear.
# Harvests the native JSONL transcript; no snapshot file, no PreCompact dependency.
# Output: plain stdout injected as context by Claude Code (≤2000 chars target).

set -euo pipefail
shopt -s nullglob

INPUT=$(cat)
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"
[[ -z "$SESSION_ID" ]] && exit 0

SOURCE=$(/usr/bin/jq -r '.source // empty' <<<"$INPUT")
TP=$(/usr/bin/jq -r '.transcript_path // empty' <<<"$INPUT")
[[ -z "$TP" ]] && exit 0

# ── Resolve the transcript to harvest ────────────────────────────────────────

HARVEST_TP=""
PROJ_DIR=""

case "$SOURCE" in
compact | resume | fork)
	# transcript_path IS the current session — harvest directly
	[[ -f "$TP" ]] && HARVEST_TP="$TP"
	;;
clear)
	# Read the pointer written by session-end-pointer.sh for this project slug
	SLUG=$(basename "$(dirname "$TP")")
	POINTER="$HOME/.claude/session-env/by-project/$SLUG/last-clear.json"
	if [[ -f "$POINTER" ]]; then
		PREV_SID=$(/usr/bin/jq -r '.session_id // empty' "$POINTER")
		PREV_TP=$(/usr/bin/jq -r '.transcript_path // empty' "$POINTER")
		# Reject if pointer is stale (>120s) or somehow points at the current session
		if [[ -n "$PREV_TP" && -f "$PREV_TP" && "$PREV_SID" != "$SESSION_ID" ]]; then
			AGE=$(($(date +%s) - $(stat -c '%Y' "$POINTER")))
			[[ $AGE -le 120 ]] && HARVEST_TP="$PREV_TP"
		fi
	fi
	;;
startup)
	# Scan siblings: newest file that is not the current session, not a bg session,
	# has at least one tool_use, and was modified within the past 2 hours.
	PROJ_DIR=$(dirname "$TP")
	CUTOFF=$(($(date +%s) - 7200))
	BEST=""
	BEST_MTIME=0
	for candidate in "$PROJ_DIR"/*.jsonl; do
		[[ "$candidate" == "$TP" ]] && continue
		MTIME=$(stat -c '%Y' "$candidate" 2>/dev/null || echo 0)
		[[ $MTIME -lt $CUTOFF ]] && continue
		[[ $MTIME -le $BEST_MTIME ]] && continue
		# Skip bg sessions and degenerate files (no tool_use = just ai-title/agent-name)
		BG=$(/usr/bin/jq -r 'select(.sessionKind=="bg") | "bg"' "$candidate" 2>/dev/null | head -1)
		[[ "$BG" == "bg" ]] && continue
		HAS_TOOL=$(/usr/bin/jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | "yes"' "$candidate" 2>/dev/null | head -1)
		[[ "$HAS_TOOL" != "yes" ]] && continue
		BEST="$candidate"
		BEST_MTIME=$MTIME
	done
	[[ -n "$BEST" ]] && HARVEST_TP="$BEST"
	;;
esac

[[ -z "$HARVEST_TP" || ! -f "$HARVEST_TP" ]] && exit 0

# ── Single-pass jq harvest ────────────────────────────────────────────────────
# Accumulates: title, last prompt, files touched, test commands+pass/fail,
# last error, compact summary sections 8+9, compaction loss stats.

HARVEST=$(/usr/bin/jq -rn '
def abbrev: . // "" | split("/") | if length > 2 then .[-2:] else . end | join("/");
def testish: test("\\b(make|npm|pnpm|yarn|bun|mvn|gradle|pytest|cargo|go|bats|shellcheck)\\s+(test|build|check|verify|lint|install)\\b");

reduce inputs as $l (
  {title:"", prompt:"", files:[], cmds:{}, tests:[], lastErr:"", summary:"", dropped:0};

  if $l.type == "ai-title" then
    .title = $l.aiTitle

  elif $l.type == "last-prompt" then
    .prompt = ($l.lastPrompt // "")

  elif $l.type == "file-history-delta" then
    .files = (.files + [($l.trackingPath | abbrev)])

  elif $l.isCompactSummary == true then
    .summary = ($l.message.content // "")

  elif $l.type == "system" and $l.subtype == "compact_boundary" then
    .dropped = ($l.compactMetadata.cumulativeDroppedTokens // 0)

  elif $l.type == "assistant" then
    reduce ($l.message.content[]? | select(.type=="tool_use")) as $t (.;
      if ($t.name | test("^(Write|Edit|MultiEdit|NotebookEdit)$")) then
        .files = (.files + [($t.input.file_path | abbrev)])
      elif $t.name == "Bash" and ($t.input.command // "" | testish) then
        .cmds[$t.id] = ($t.input.command | split("\n")[0])
      else . end)

  elif $l.type == "user" then
    reduce ($l.message.content[]? | select(.type == "tool_result")) as $r (.;
      if .cmds[$r.tool_use_id] then
        .tests = (.tests + [{
          cmd: .cmds[$r.tool_use_id],
          ok: (($l.toolUseResult | type) != "string")
        }])
      else . end)
    | if ($l.toolUseResult | type) == "string"
         and ($l.toolUseResult | test("^Error: Exit code"))
      then .lastErr = $l.toolUseResult
      else . end

  else . end
)
| {
    title,
    prompt: (.prompt | .[0:200]),
    dropped,
    files: (.files | map(select(. != "" and . != null)) | unique | .[0:8]),
    tests: (.tests | unique_by(.cmd) | .[-4:]),
    lastErr: (.lastErr | .[0:150]),
    hasSummary: (.summary != ""),
    summary8: (
      .summary
      | gsub("\\*{1,2}"; "")
      | split("\n")
      | reduce .[] as $line (
          {capture: false, lines: []};
          if ($line | test("^ *[0-9]+\\.\\s+(Current Work)"))
            then {capture: true, lines: []}
          elif .capture and ($line | test("^ *[0-9]+\\.\\s+"))
            then {capture: false, lines: .lines}
          elif .capture
            then {capture: .capture, lines: (.lines + [$line])}
          else . end)
      | .lines | join(" ") | ltrimstr(" ") | .[0:350]
    ),
    summary9: (
      .summary
      | gsub("\\*{1,2}"; "")
      | split("\n")
      | reduce .[] as $line (
          {capture: false, lines: []};
          if ($line | test("^ *[0-9]+\\.\\s+(Optional Next Step)"))
            then {capture: true, lines: []}
          elif .capture and ($line | test("^ *[0-9]+\\.\\s+"))
            then {capture: false, lines: .lines}
          elif .capture
            then {capture: .capture, lines: (.lines + [$line])}
          else . end)
      | .lines | join(" ") | ltrimstr(" ") | .[0:300]
    )
  }
' "$HARVEST_TP" 2>/dev/null) || exit 0

[[ -z "$HARVEST" ]] && exit 0

# ── Format output ─────────────────────────────────────────────────────────────

SLUG=$(basename "$(dirname "$HARVEST_TP")")
AGE_SECS=$(($(date +%s) - $(stat -c '%Y' "$HARVEST_TP" 2>/dev/null || date +%s)))
if [[ $AGE_SECS -lt 60 ]]; then
	AGE="${AGE_SECS}s ago"
elif [[ $AGE_SECS -lt 3600 ]]; then
	AGE="$((AGE_SECS / 60))m ago"
else
	AGE="$((AGE_SECS / 3600))h ago"
fi

TITLE=$(/usr/bin/jq -r '.title // ""' <<<"$HARVEST")
PROMPT=$(/usr/bin/jq -r '.prompt // ""' <<<"$HARVEST")
DROPPED=$(/usr/bin/jq -r '.dropped' <<<"$HARVEST")
HAS_SUMMARY=$(/usr/bin/jq -r '.hasSummary' <<<"$HARVEST")
S8=$(/usr/bin/jq -r '.summary8 // ""' <<<"$HARVEST")
S9=$(/usr/bin/jq -r '.summary9 // ""' <<<"$HARVEST")
LAST_ERR=$(/usr/bin/jq -r '.lastErr // ""' <<<"$HARVEST")
FILES=$(/usr/bin/jq -r '.files | join(", ")' <<<"$HARVEST")
TESTS=$(/usr/bin/jq -r '.tests | map("\(.cmd[0:50]) \(if .ok then "OK" else "FAIL" end)") | join("\n  ")' <<<"$HARVEST")

OUT=""
OUT+="--- Handover: $SOURCE from $SLUG [$AGE] ---"$'\n'
[[ -n "$TITLE" ]] && OUT+="Title: $TITLE"$'\n'

if [[ "$SOURCE" != "compact" ]]; then
	[[ -n "$PROMPT" ]] && OUT+="Last prompt: $PROMPT"$'\n'
	if [[ -n "$S8" ]]; then
		OUT+="Current work: $S8"$'\n'
	fi
	if [[ -n "$S9" ]]; then
		OUT+="Next step: $S9"$'\n'
	fi
fi

[[ -n "$FILES" ]] && OUT+="Files touched: $FILES"$'\n'
[[ -n "$LAST_ERR" ]] && OUT+="Last error: $LAST_ERR"$'\n'
[[ -n "$TESTS" ]] && OUT+="Tests:"$'\n'"  $TESTS"$'\n'
[[ $DROPPED -gt 0 ]] && OUT+="Context lost to compaction: $DROPPED tokens"$'\n'

if [[ "$HAS_SUMMARY" == "true" && "$SOURCE" != "compact" ]]; then
	OUT+="(Decision context in native compaction summary above)"$'\n'
fi

printf '%s' "$OUT"
