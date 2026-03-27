function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(tv sesh)
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}

zle     -N             sesh-sessions
bindkey -M emacs '^p' sesh-sessions
bindkey -M vicmd '^p' sesh-sessions
bindkey -M viins '^p' sesh-sessions
