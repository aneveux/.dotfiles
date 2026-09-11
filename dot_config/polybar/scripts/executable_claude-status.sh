#!/usr/bin/env bash

# claude-status.sh — aggregate Claude Code session state for Polybar
#
#   status  (default)  print the robot glyph coloured by the most urgent state,
#                      empty when no session is alive
#   focus              raise the terminal of the session that most needs you
#
# Doubles as the reaper: Claude Code fires no event on Esc/Ctrl-C and does not
# reliably fire SessionEnd on SIGKILL, so liveness cannot come from the event
# stream. Dead sessions are detected here via /proc.

export LC_ALL=C

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/claude-status"
DEBUG_LOG="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/claude-status-debug.log"
BUSY_TTL=600   # busy not refreshed this long is shown as waiting (backstop)
HARD_TTL=43200 # any state file older than this is deleted outright
LOCK_TTL=600   # orphan .lock files older than this are deleted

# nf-md-robot U+F06A9, as explicit UTF-8 bytes: LC_ALL=C above would make bash
# leave a \U escape unexpanded, since the codepoint is not representable in C.
GLYPH=$'\xf3\xb0\x9a\xa9'
COL_ATTN="#f38ba8" # red      question / permission
COL_DONE="#fab387" # peach    turn finished / error
COL_RUN="#a6e3a1"  # green    working
COL_IDLE="#7f849c" # overlay1 alive but never used

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
	S_PPID=${arr[1]:-0}
	S_START=${arr[19]:-0}
	return 0
}

declare -A F=()
load_file() {
	local line kv
	F=()
	read -r line <"$1" 2>/dev/null || return 1
	[[ -n $line ]] || return 1
	for kv in $line; do F[${kv%%=*}]=${kv#*=}; done
	[[ -n ${F[state]:-} ]]
}

declare -a CNT=(0 0 0 0)
BEST=-1 BEST_FILE= BEST_TS=0

scan() {
	local f base st pid start ts act rank now alive
	now=$EPOCHSECONDS
	shopt -s nullglob

	# Keep the opt-in trace from filling tmpfs; free when tracing is off.
	if [[ -e $STATE_DIR/.debug ]] &&
		(($(stat -c%s "$DEBUG_LOG" 2>/dev/null || echo 0) > 4194304)); then
		: >"$DEBUG_LOG"
	fi

	for f in "$STATE_DIR"/*; do
		base=${f##*/}
		case $base in
		*.tmp.*) continue ;;
		*.lock)
			[[ -e ${f%.lock} ]] && continue
			[[ -n $(find "$f" -maxdepth 0 -mmin +$((LOCK_TTL / 60)) 2>/dev/null) ]] &&
				rm -f -- "$f"
			continue
			;;
		esac

		load_file "$f" || continue
		st=${F[state]}
		pid=${F[pid]:-0}
		start=${F[start]:-0}
		ts=${F[ts]:-0}
		[[ $ts =~ ^[0-9]+$ ]] || ts=0
		# ts is when the state was set, act is the last activity from any writer
		# (main agent or subagent). Freshness must go by act, or a session whose
		# state is pinned while subagents work would be downgraded.
		act=${F[act]:-$ts}
		[[ $act =~ ^[0-9]+$ ]] || act=$ts

		if ((now - act > HARD_TTL)); then
			rm -f -- "$f" "$f.lock"
			continue
		fi

		# starttime is checked alongside the pid so a recycled pid that happens
		# to be named claude cannot resurrect a dead session.
		if [[ $pid =~ ^[0-9]+$ ]] && ((pid > 1)); then
			alive=0
			if read_stat "$pid" &&
				[[ $S_COMM == claude || $S_COMM == node ]] &&
				{ [[ $start == 0 ]] || [[ $S_START == "$start" ]]; }; then
				alive=1
			fi
			if ((!alive)); then
				rm -f -- "$f" "$f.lock"
				continue
			fi
		fi

		if [[ $st == busy || $st == idle ]] && ((now - act > BUSY_TTL)); then
			st=waiting
		fi

		case $st in
		question | permission) rank=3 ;;
		waiting | error) rank=2 ;;
		busy) rank=1 ;;
		idle) rank=0 ;;
		*) continue ;;
		esac

		((CNT[rank]++))
		if ((rank > BEST)) || { ((rank == BEST)) && ((ts < BEST_TS)); }; then
			BEST=$rank
			BEST_FILE=$f
			BEST_TS=$ts
		fi
	done
}

cmd_status() {
	scan
	((BEST < 0)) && {
		echo ""
		return 0
	}
	local col n
	case $BEST in
	3) col=$COL_ATTN ;;
	2) col=$COL_DONE ;;
	1) col=$COL_RUN ;;
	0) col=$COL_IDLE ;;
	esac
	n=${CNT[BEST]}
	if ((n > 1)); then
		printf '%%{F%s}%s%%{F-}  %d\n' "$col" "$GLYPH" "$n"
	else
		printf '%%{F%s}%s%%{F-}\n' "$col" "$GLYPH"
	fi
}

win_exists() { [[ $1 =~ ^[0-9]+$ ]] && xdotool getwindowname "$1" >/dev/null 2>&1; }

activate() {
	win_exists "$1" || return 1
	i3-msg -q "[id=$1] focus" >/dev/null 2>&1 || xdotool windowactivate "$1" 2>/dev/null
}

# First ancestor of $1 that owns an X window.
term_window_for() {
	local p=$1 w
	for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
		read_stat "$p" || return 1
		[[ $S_COMM == i3 || $S_COMM == systemd ]] && return 1
		w=$(xdotool search --pid "$p" 2>/dev/null | head -n1)
		[[ -n $w ]] && {
			printf '%s\n' "$w"
			return 0
		}
		((S_PPID <= 1)) && return 1
		p=$S_PPID
	done
	return 1
}

cmd_focus() {
	scan
	((BEST < 0)) && return 0
	load_file "$BEST_FILE" || return 0

	local pane=${F[pane]:-'-'} sock=${F[sock]:-'-'} win=${F[win]:-'-'} pid=${F[pid]:-0}
	local -a tm=(tmux)
	[[ $sock != '-' ]] && tm=(tmux -S "$sock")

	if [[ $pane != '-' ]]; then
		local sess wid cline cname cpid twin
		read -r sess wid < <("${tm[@]}" display-message -pt "$pane" \
			'#{session_name} #{window_id}' 2>/dev/null)
		if [[ -n ${sess:-} ]]; then
			cline=$("${tm[@]}" list-clients -t "$sess" \
				-F '#{client_name} #{client_pid}' 2>/dev/null | head -n1)
			if [[ -z $cline ]]; then
				# Detached session: steal an existing client rather than
				# spawning a new terminal.
				cline=$("${tm[@]}" list-clients \
					-F '#{client_name} #{client_pid}' 2>/dev/null | head -n1)
				read -r cname cpid <<<"$cline"
				[[ -n ${cname:-} ]] &&
					"${tm[@]}" switch-client -c "$cname" -t "$sess" 2>/dev/null
			else
				read -r cname cpid <<<"$cline"
			fi
			"${tm[@]}" select-window -t "$wid" 2>/dev/null
			"${tm[@]}" select-pane -t "$pane" 2>/dev/null
			# Resolve the host terminal live: a stored WINDOWID goes stale when
			# the tmux client re-attaches from another window.
			twin=
			[[ -n ${cpid:-} ]] && twin=$(term_window_for "$cpid")
			activate "${twin:-$win}" || activate "$win"
			return 0
		fi
	fi

	activate "$win" && return 0
	local bwin
	bwin=$(term_window_for "$pid") && activate "$bwin"
	return 0
}

case "${1:-status}" in
focus)
	cmd_focus
	;;
status)
	cmd_status
	;;
*)
	cmd_status
	;;
esac
