function sesh-sessions() {
  BUFFER="tv sesh"
  zle accept-line
}

zle     -N             sesh-sessions
zvm_bindkey viins '^o' sesh-sessions
zvm_bindkey vicmd '^o' sesh-sessions
bindkey -M emacs '^o' sesh-sessions
