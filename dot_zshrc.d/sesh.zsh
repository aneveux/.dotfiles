function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list --icons | fzf --ansi --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '^t' sesh-sessions
bindkey -M vicmd '^t' sesh-sessions
bindkey -M viins '^t' sesh-sessions
