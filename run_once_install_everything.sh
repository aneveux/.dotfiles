#!/usr/bin/env bash
set -euo pipefail

# --- Colors and symbols (fallback if gum not available) ---
bold=$(tput bold 2>/dev/null || echo "")
reset=$(tput sgr0 2>/dev/null || echo "")
red=$(tput setaf 1 2>/dev/null || echo "")
green=$(tput setaf 2 2>/dev/null || echo "")
blue=$(tput setaf 4 2>/dev/null || echo "")

ok="✔"
err="✖"
run="➜"

# --- Mode selection ---
APPLY=false
if [[ "${1:-}" == "--apply" ]]; then
  APPLY=true
fi

# --- Detect package manager ---
if command -v yay &>/dev/null; then
  PKG="yay -S --needed --noconfirm"
elif command -v pacman &>/dev/null; then
  PKG="sudo pacman -S --needed --noconfirm"
else
  echo "${red}${err} Error:${reset} No supported package manager found (pacman/yay required)"
  exit 1
fi

# --- Section printing (gum or ascii) ---
if command -v gum &>/dev/null; then
  section() {
    gum style \
      --border normal \
      --margin "1 0" \
      --padding "0 2" \
      --border-foreground cyan \
      "${1}"
  }
else
  section() {
    local title=$1
    local line
    line=$(printf "%*s" $((${#title} + 4)) "" | tr " " "-")
    echo
    echo "+${line}+"
    echo "|  ${title}  |"
    echo "+${line}+"
  }
fi

# Check if a package is already installed
is_installed() {
  pacman -Qq "$1" &>/dev/null
}

# Run a command, skipping already-installed pkgs
run_cmd() {
  local all_pkgs=("$@")
  local to_install=()

  # filter out installed packages only if applying
  if $APPLY; then
    for pkg in "${all_pkgs[@]}"; do
      if ! is_installed "$pkg"; then
        to_install+=("$pkg")
      fi
    done
  else
    # in dry-run, show full command
    to_install=("${all_pkgs[@]}")
  fi

  local cmd="$PKG ${to_install[*]}"

  if ((${#to_install[@]} == 0)); then
    echo " ${green}${ok}${reset} All packages already installed"
    return 0
  fi

  # Correct dry-run/apply label
  local mode="[dry-run]"
  if $APPLY; then
    mode="[apply]"
  fi
  echo " ${blue}${run}${reset} ${bold}$mode $cmd${reset}"

  if $APPLY; then
    if command -v gum &>/dev/null; then
      if gum spin --spinner line --title "Installing..." -- \
        bash -c "$cmd"; then
        echo "   ${green}${ok}${reset} Done"
      else
        echo "   ${red}${err}${reset} Failed"
      fi
    else
      if eval "$cmd"; then
        echo "   ${green}${ok}${reset} Done"
      else
        echo "   ${red}${err}${reset} Failed"
      fi
    fi
  fi
}

banner() {
  local msg="🚀 Installing tools (APPLY=${APPLY:-false})"

  if command -v gum &>/dev/null; then
    # Fancy gum banner
    gum style \
      --border double \
      --margin "1 0" \
      --padding "1 3" \
      --align center \
      --border-foreground magenta \
      "$msg"
  else
    # ASCII fallback
    local line
    line=$(printf "%*s" $((${#msg} + 4)) "" | tr " " "=")
    echo
    echo "$line"
    echo "| $msg |"
    echo "$line"
  fi
}

# --- System utilities ---
# shellcheck disable=SC2034  # Appears unused but used via eval
SYSTEM=(
  curl        # Data transfer tool
  gnupg       # GPG encryption
  openvpn     # VPN client
  rsync       # File synchronization
  7zip        # Archive manager
  xclip       # Clipboard manager
  numlockx    # Enable numlock on startup
  blueman     # Bluetooth manager
  feh         # Lightweight image viewer
  imagemagick # Image manipulation
  ffmpeg      # Video/Audio processing
  playerctl   # Media player controller
  vlc         # Media player
)

# --- CLI tools ---
# shellcheck disable=SC2034  # Appears unused but used via eval
CLI=(
  bat       # cat with syntax highlighting
  fd        # fast find
  fzf       # fuzzy finder
  eza       # modern ls
  ripgrep   # fast grep
  jq        # JSON processor
  yq        # YAML processor
  ncdu      # Disk usage analyzer
  htop      # Process viewer
  gotop     # activity monitor
  lnav      # Log file navigator
  most      # Pager
  tldr      # Simplified man pages
  zoxide    # Smarter cd
  navi      # Interactive cheatsheet
  yazi      # TUI file manager
  atuin     # Shell history manager
  gum       # Terminal UI components
  mods      # AI tool integration
  sesh-bin  # Session manager
  cbonsai   # useless but fun, bonsai tree in shell
  crush-bin # ai coding agent by charmbracelet
)

# --- Development tools ---
# shellcheck disable=SC2034  # Appears unused but used via eval
DEV=(
  git                    # Version control
  git-delta              # Git diff viewer
  git-secrets            # Prevent committing secrets
  github-cli             # GitHub CLI
  lazygit                # TUI git client
  lazydocker             # TUI docker client
  docker                 # Container runtime
  docker-credential-pass # Docker credential helper
  jdk-openjdk            # Java JDK
  hugo                   # Static site generator
  luarocks               # Lua package manager
  mise                   # Tool version manager
)

# --- Shell & terminal ---
# shellcheck disable=SC2034  # Appears unused but used via eval
SHELL=(
  zsh                     # Z shell
  zsh-autosuggestions     # Autosuggestions for zsh
  zsh-completions         # Extra completions
  zsh-syntax-highlighting # Syntax highlighting
  kitty                   # GPU terminal
  kitty-shell-integration
  kitty-terminfo
  tmux       # Terminal multiplexer
  tmuxinator # Tmux session manager
  dmenu      # Application launcher
  rofi       # Alternative app launcher
  chezmoi    # Dotfile manager
)

# --- Desktop environment ---
# shellcheck disable=SC2034  # Appears unused but used via eval
DESKTOP=(
  i3-wm        # Window manager
  i3lock-color # Screen locker
  dunst        # Notification daemon
  polybar      # Status bar
  picom        # Compositor
  redshift     # Adjust screen color
  xautolock    # Idle locker
  flameshot    # Screenshot tool
  chromium     # Browser
  firefox      # Browser
)

# --- Applications ---
# shellcheck disable=SC2034  # Appears unused but used via eval
APPS=(
  discord           # Chat
  slack-desktop     # Chat
  obsidian          # Notes
  spotify           # Music
  nextcloud-client  # Cloud sync
  jetbrains-toolbox # JetBrains IDE manager
)

# --- Fonts & themes ---
# shellcheck disable=SC2034  # Appears unused but used via eval
FONTS=(
  adobe-source-code-pro-fonts
  noto-fonts
  noto-fonts-emoji
  ttf-jetbrains-mono
  ttf-juliamono
  ttf-nerd-fonts-symbols
  ttf-nerd-fonts-symbols-common
  catppuccin-cursors-mocha
  catppuccin-gtk-theme-mocha
  epapirus-icon-theme
  papirus-icon-theme
  x11-emoji-picker-git
)

# --- Updaters & meta tools ---
# shellcheck disable=SC2034  # Appears unused but used via eval
EXTRAS=(
  topgrade-bin # Auto-update everything
  yay          # AUR helper
  bluetui      # TUI for bluetooth management
)

banner

# --- Install all categories ---
for category in SYSTEM CLI DEV SHELL DESKTOP APPS FONTS EXTRAS; do
  section "$category"
  mapfile -t pkgs < <(eval "printf '%s\n' \${${category}[@]}")
  run_cmd "${pkgs[@]}"
done

section "All tools installed!"
echo " ${green}${ok}${reset} ${bold}Everything is ready 🎉${reset}"
