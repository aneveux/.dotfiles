# Basic listing (no icons, to avoid annoying completions)
ls() {
  eza --color=auto --header "$@"
}

# Like `ls`, but with icons always on
l() {
  eza --color=auto --header --icons=always "$@"
}

# Like `ls -l` but better: long view, group directories first, show hidden files
ll() {
  eza --color=auto --group-directories-first --long --header --all --icons=always "$@"
}

# Tree view (for directory structure), with icons
lll() {
  eza --color=auto --header --tree --icons=always "$@"
}

# List all (even dotfiles), in a compact format with icons
la() {
  eza --color=auto --all --header --icons=always "$@"
}

# Long view, sorted by time (most recently modified files last)
lt() {
  eza --color=auto --long --header --sort newest --icons=always "$@"
}

# Only show directories
ld() {
  eza --color=auto --header --icons=always --only-dirs "$@"
}

