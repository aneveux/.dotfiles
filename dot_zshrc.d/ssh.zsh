# Ships xterm-ghostty and tmux-256color terminfo to a host on first connect so
# the remote TERM matches what it talks to, including from tmux panes where
# ghostty's own ssh integration never loads. Modeled on ghostty's zsh
# shell-integration ssh(); hosts are tracked with `ghostty +ssh-cache`.
function ssh() {
	local remote_term
	case $TERM in
	xterm-ghostty | tmux-256color) remote_term=$TERM ;;
	*)
		command ssh "$@"
		return
		;;
	esac
	if (( ! $+commands[ghostty] || ! $+commands[infocmp] )); then
		command ssh "$@"
		return
	fi

	local ssh_user ssh_host key value
	while read -r key value; do
		case $key in
		user) ssh_user=$value ;;
		hostname) ssh_host=$value ;;
		esac
	done < <(command ssh -G "$@" 2>/dev/null)
	if [[ -z $ssh_user || -z $ssh_host ]]; then
		command ssh "$@"
		return
	fi

	local target="$ssh_user@$ssh_host" control_dir
	local -a ssh_opts=(-o "SetEnv COLORTERM=truecolor")
	if ! ghostty +ssh-cache --host="$target" >/dev/null 2>&1; then
		print -u2 "Setting up xterm-ghostty and tmux-256color terminfo on $ssh_host..."
		control_dir=$(mktemp -d -t ghostty-ssh.XXXXXX) || {
			command ssh "$@"
			return
		}
		if { infocmp -0 -x xterm-ghostty && infocmp -0 -x tmux-256color } 2>/dev/null |
			command ssh -o ControlMaster=yes -o ControlPath="$control_dir/socket" -o ControlPersist=60s "$@" '
				infocmp xterm-ghostty >/dev/null 2>&1 && infocmp tmux-256color >/dev/null 2>&1 && exit 0
				command -v tic >/dev/null 2>&1 || exit 1
				mkdir -p ~/.terminfo && tic -x - 2>/dev/null
			' 2>/dev/null; then
			ghostty +ssh-cache --add="$target" >/dev/null 2>&1
			ssh_opts+=(-o "ControlPath=$control_dir/socket")
		else
			print -u2 "Could not install terminfo on $ssh_host, falling back to xterm-256color"
			remote_term=xterm-256color
		fi
	fi

	TERM=$remote_term command ssh "${ssh_opts[@]}" "$@"
	local ssh_status=$?
	[[ -n $control_dir ]] && rm -rf -- "$control_dir"
	return $ssh_status
}
