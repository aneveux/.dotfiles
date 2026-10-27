function sesh-sessions() {
  BUFFER="sesh picker -idH"
  zle accept-line
}

_sesh_preexec() {
  [[ "$1" == "sesh picker -idH" ]] && printf '\e[2K\e[1A\e[2K\r' >/dev/tty
}
preexec_functions+=(_sesh_preexec)

zle     -N             sesh-sessions
# zvm_bindkey before zvm_init leaves a dangling zvm_readkeys_handler binding that segfaults zsh 5.9
zvm_after_init_commands+=(
  "zvm_bindkey viins '^[s' sesh-sessions"
  "zvm_bindkey vicmd '^[s' sesh-sessions"
)
bindkey -M emacs '^[s' sesh-sessions
