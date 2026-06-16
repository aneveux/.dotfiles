function sesh-sessions() {
  if [[ -n "${TMUX:-}" ]]; then
    tmux display-popup -E -w 80% -h 70% -d '#{pane_current_path}' -T 'Sesh' "tv sesh"
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
