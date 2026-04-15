function sesh-sessions() {
  exec </dev/tty
  local selected
  selected=$(tv sesh) || { zle reset-prompt > /dev/null 2>&1 || true; return; }
  if [[ -n "$selected" ]]; then
    sesh connect "$selected"
  fi
  zle reset-prompt > /dev/null 2>&1 || true
}

zle     -N             sesh-sessions
zvm_bindkey viins '^o' sesh-sessions
zvm_bindkey vicmd '^o' sesh-sessions
bindkey -M emacs '^o' sesh-sessions
