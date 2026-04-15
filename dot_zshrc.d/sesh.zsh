function sesh-sessions() {
  exec </dev/tty
  local session
  session=$(tv sesh)
  zle reset-prompt > /dev/null 2>&1 || true
  [[ -z "$session" ]] && return
  sesh connect "$session"
}

zle     -N             sesh-sessions
zvm_bindkey viins '^o' sesh-sessions
zvm_bindkey vicmd '^o' sesh-sessions
bindkey -M emacs '^o' sesh-sessions
