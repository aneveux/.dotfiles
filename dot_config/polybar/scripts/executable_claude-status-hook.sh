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

# The record is space-separated and tool is the one field that reaches it
# straight from jq, so a tool name with a space would corrupt the line.
tool=${tool//[^A-Za-z0-9._-]/_}

win=${WINDOWID:-}
[[ $win =~ ^[0-9]+$ ]] || win=-

pane=${TMUX_PANE:-}
[[ $pane =~ ^%[0-9]+$ ]] || pane=-

sock=${TMUX%%,*}
sock=${sock//[^A-Za-z0-9._\/-]/_}
sock=${sock:--}

# Sets a global rather than echoing: this runs on every tool call of every
# session, so it must not fork a subshell.
RANK=-1
set_rank() {
	case $1 in
	question | permission) RANK=3 ;;
	waiting | error) RANK=2 ;;
	busy) RANK=1 ;;
	idle) RANK=0 ;;
	*) RANK=-1 ;;
	esac
}

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

# Opt-in tracing: `touch $STATE_DIR/.debug`. Costs one builtin test when off.
# Lives outside STATE_DIR so the reader's glob never sees it.
DEBUG_LOG=
[[ -e $STATE_DIR/.debug ]] &&
	DEBUG_LOG="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/claude-status-debug.log"

f="$STATE_DIR/$sid"
# Lock a separate stable inode: the mv below replaces the state file's inode,
# so locking the state file itself would give two writers no exclusion.
exec 9>"$f.lock" 2>/dev/null || exit 0
flock -x -w 2 9 2>/dev/null || exit 0

oseq=0 ostate= ots= otool=
if [[ -r $f ]] && read -r line <"$f" 2>/dev/null; then
	for kv in $line; do
		case $kv in
		seq=*) oseq=${kv#seq=} ;;
		state=*) ostate=${kv#state=} ;;
		ts=*) ots=${kv#ts=} ;;
		tool=*) otool=${kv#tool=} ;;
		esac
	done
fi
[[ $oseq =~ ^[0-9]+$ ]] || oseq=0
[[ $ots =~ ^[0-9]+$ ]] || ots=$NOW
[[ $otool == - ]] && otool=

((SEQ < oseq)) && exit 0

if [[ $state == gone ]]; then
	# No further event can arrive for this session id, so the lock goes too
	# rather than waiting for the reader to reap it.
	rm -f -- "$f" "$f.lock"
	exit 0
fi

# A session has ONE state slot but many writers: the main agent plus every
# subagent, all sharing session_id. So a subagent's `busy` heartbeat would erase
# the main agent's `question` and turn the bar green while you are being asked
# something. Rule: raising the rank is always allowed, lowering it only when the
# event proves you acted or the turn ended.
#
# Note this does not rely on agent_id: a subagent PreToolUse is blocked for being
# a generic `busy` against a rank-3 state, not for being tagged as a subagent.
# The agent_id arm below only stops a stray subagent flipping a finished session
# back from waiting to busy.
apply=1
set_rank "$state"
nrank=$RANK
set_rank "$ostate"
orank=$RANK

if ((orank >= 0 && nrank < orank)); then
	if ((orank == 3)); then
		case $event in
		UserPromptSubmit | Stop | StopFailure) ;;
		PostToolUse | PostToolUseFailure)
			# Only the question's own tool returning means you answered.
			[[ -n $otool && $tool == "$otool" ]] || apply=0
			;;
		*) apply=0 ;;
		esac
	elif [[ -n $agent ]]; then
		apply=0
	fi
fi

if ((apply)); then
	wstate=$state wseq=$SEQ wts=$NOW
	if ((nrank == 3)); then wtool=${tool:--}; else wtool=-; fi
else
	# Preserve seq too: advancing it would let this blocked event lock out a
	# legitimate later write from the main agent.
	wstate=$ostate wseq=$oseq wts=$ots wtool=${otool:--}
fi

if [[ -n $DEBUG_LOG ]]; then
	printf '%s sid=%s ev=%s tool=%s agent=%s %s->%s applied=%s\n' \
		"$NOW" "$sid" "$event" "${tool:--}" "${agent:--}" \
		"${ostate:--}" "$state" "$apply" >>"$DEBUG_LOG" 2>/dev/null
fi

tmp="$f.tmp.$$"
if printf 'state=%s seq=%s ts=%s act=%s tool=%s pid=%s start=%s win=%s pane=%s sock=%s proj=%s mode=%s\n' \
	"$wstate" "$wseq" "$wts" "$NOW" "$wtool" "$cpid" "$cstart" "$win" "$pane" "$sock" "$proj" "$pmode" \
	>"$tmp" 2>/dev/null; then
	mv -f -- "$tmp" "$f" 2>/dev/null
fi
rm -f -- "$tmp" 2>/dev/null
exit 0
