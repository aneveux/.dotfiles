function mkcd () { mkdir -p -- "$@" && builtin cd -- "${@[-1]}"; }
