function sesh-sessions() {
  BUFFER="tv sesh"
  zle accept-line
}

_sesh_preexec() {
  [[ "$1" == "tv sesh" ]] && printf '\e[2K\e[1A\e[2K\r' >/dev/tty
}
preexec_functions+=(_sesh_preexec)

zle     -N             sesh-sessions
zvm_bindkey viins '^o' sesh-sessions
zvm_bindkey vicmd '^o' sesh-sessions
bindkey -M emacs '^o' sesh-sessions
