function sesh-sessions() {
  exec </dev/tty
  if [[ -n "${TMUX:-}" ]]; then
    tv sesh
  else
    tmux new-session -s _sesh_picker 'tv sesh; exit'
    tmux kill-session -t _sesh_picker 2>/dev/null
  fi
  zle reset-prompt > /dev/null 2>&1 || true
}

zle     -N             sesh-sessions
zvm_bindkey viins '^o' sesh-sessions
zvm_bindkey vicmd '^o' sesh-sessions
bindkey -M emacs '^o' sesh-sessions
