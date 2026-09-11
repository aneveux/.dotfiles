#!/usr/bin/env bash

# claude-status-hook.sh — Claude Code session state -> polybar state dir.
#
# Payload-driven: takes NO arguments. The state is derived from the stdin JSON
# so that exactly ONE hook writes per event, which is what makes the wildcard
# PreToolUse heartbeat and the AskUserQuestion detection unable to race.
#
# Concurrency: per-session flock on a separate inode + monotonic seq
# compare-and-swap, so a late async write can never clobber a newer state.
#
# ALWAYS exits 0: exit 2 on Stop would stop Claude from stopping, and on
# UserPromptSubmit it would erase the prompt.

export LC_ALL=C

# Must be the very first thing: the sequence has to reflect event time, not
# write time, or the CAS cannot order two hooks racing for the same session.
SEQ=${EPOCHREALTIME/./}
NOW=${EPOCHREALTIME%.*}

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/claude-status"

trap 'exit 0' EXIT
[[ $SEQ =~ ^[0-9]+$ ]] || exit 0

payload=$(cat) || exit 0
[[ -n $payload ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

fields=$(printf '%s' "$payload" | jq -r '
  [ (.session_id       // ""),
    (.hook_event_name  // ""),
    (.tool_name        // ""),
    (.notification_type// ""),
    (.cwd              // ""),
    (.permission_mode  // ""),
    (.agent_id         // "")
  ] | join("\u001f")' 2>/dev/null) || exit 0

# Unit separator, not tab: tab is IFS whitespace, so bash would collapse runs of
# it and shift every field after an empty one. Notification events always have an
# empty tool_name, so tab would misparse every single one of them.
IFS=$'\037' read -r sid event tool ntype cwd pmode agent <<<"$fields"

# session_id doubles as a filename: refuse anything not obviously safe.
[[ $sid =~ ^[A-Za-z0-9._-]{4,80}$ ]] || exit 0

state=
case $event in
SessionStart) state=idle ;;
UserPromptSubmit) state=busy ;;
PreToolUse)
	case $tool in
	AskUserQuestion | ExitPlanMode) state=question ;;
	*) state=busy ;;
	esac
	;;
PostToolUse | PostToolUseFailure) state=busy ;;
PermissionRequest) state=permission ;;
Notification)
	case $ntype in
	permission_prompt) state=permission ;;
	elicitation_dialog | agent_needs_input) state=question ;;
	idle_prompt | agent_completed) state=waiting ;;
	*) exit 0 ;;
	esac
	;;
Stop)
	# A subagent stopping does not mean the main session is waiting on you.
	if [[ -n $agent ]]; then state=busy; else state=waiting; fi
	;;
StopFailure) state=error ;;
SessionEnd) state=gone ;;
*) exit 0 ;;
esac

proj=${cwd##*/}
proj=${proj//[^A-Za-z0-9._-]/_}
proj=${proj:--}

pmode=${pmode//[^A-Za-z]/_}
pmode=${pmode:--}

win=${WINDOWID:-}
[[ $win =~ ^[0-9]+$ ]] || win=-

pane=${TMUX_PANE:-}
[[ $pane =~ ^%[0-9]+$ ]] || pane=-

sock=${TMUX%%,*}
sock=${sock//[^A-Za-z0-9._\/-]/_}
sock=${sock:--}

S_COMM= S_PPID=0 S_START=0
read_stat() {
	local st rest arr
	[[ -r /proc/$1/stat ]] || return 1
	st=$(</proc/"$1"/stat) || return 1
	[[ -n $st ]] || return 1
	S_COMM=${st%)*}
	S_COMM=${S_COMM##*(}
	rest=${st##*') '}
	read -ra arr <<<"$rest"
	S_PPID=${arr[1]:-0}   # /proc stat field 4
	S_START=${arr[19]:-0} # /proc stat field 22
	return 0
}

cpid=0 cstart=0 p=$$
for _ in 1 2 3 4 5 6 7 8 9 10; do
	read_stat "$p" || break
	if [[ $S_COMM == claude || $S_COMM == node ]]; then
		cpid=$p
		cstart=$S_START
		break
	fi
	((S_PPID <= 1)) && break
	p=$S_PPID
done

mkdir -p -- "$STATE_DIR" 2>/dev/null || exit 0
chmod 700 -- "$STATE_DIR" 2>/dev/null

f="$STATE_DIR/$sid"
# Lock a separate stable inode: the mv below replaces the state file's inode,
# so locking the state file itself would give two writers no exclusion.
exec 9>"$f.lock" 2>/dev/null || exit 0
flock -x -w 2 9 2>/dev/null || exit 0

old=0
if [[ -r $f ]] && read -r line <"$f" 2>/dev/null; then
	for kv in $line; do
		if [[ $kv == seq=* ]]; then
			old=${kv#seq=}
			break
		fi
	done
fi
[[ $old =~ ^[0-9]+$ ]] || old=0
((SEQ < old)) && exit 0

if [[ $state == gone ]]; then
	# No further event can arrive for this session id, so the lock goes too
	# rather than waiting for the reader to reap it.
	rm -f -- "$f" "$f.lock"
	exit 0
fi

tmp="$f.tmp.$$"
if printf 'state=%s seq=%s ts=%s pid=%s start=%s win=%s pane=%s sock=%s proj=%s mode=%s\n' \
	"$state" "$SEQ" "$NOW" "$cpid" "$cstart" "$win" "$pane" "$sock" "$proj" "$pmode" \
	>"$tmp" 2>/dev/null; then
	mv -f -- "$tmp" "$f" 2>/dev/null
fi
rm -f -- "$tmp" 2>/dev/null
exit 0
