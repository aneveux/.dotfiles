function sesh-sessions() {
  if [[ -n "${TMUX:-}" ]]; then
    local session
    session=$(tv sesh < /dev/tty)
    [[ -n "$session" ]] && sesh connect "$session"
    zle reset-prompt > /dev/null 2>&1 || true
  else
    BUFFER="tmux new-session 'tv sesh'"
    zle accept-line
  fi
}

zle     -N             sesh-sessions
zvm_bindkey viins '^o' sesh-sessions
zvm_bindkey vicmd '^o' sesh-sessions
bindkey -M emacs '^o' sesh-sessions
