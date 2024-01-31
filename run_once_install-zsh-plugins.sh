#!/bin/bash

ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH/custom"
ZSH_PLUGINS="$ZSH_CUSTOM/plugins"

if [ ! -d "$ZSH" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [ ! -d "$ZSH_PLUGINS/zsh-completions/" ]; then
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_PLUGINS/zsh-completions/"
fi

if [ ! -d "$ZSH_PLUGINS/fzf-tab" ]; then
  git clone https://github.com/Aloxaf/fzf-tab "$ZSH_PLUGINS/fzf-tab"
fi

if [ ! -d "$ZSH_PLUGINS/zsh-autosuggestions" ]; then
  git clone git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_PLUGINS/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGINS/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_CUSTOM/resources" ]; then
  mkdir "$ZSH_CUSTOM/resources"
fi

if [ ! -d "$ZSH_CUSTOM/resources/zsh-syntax-highlighting" ]; then
  git clone https://github.com/catppuccin/zsh-syntax-highlighting.git "$ZSH_CUSTOM/resources/zsh-syntax-highlighting"
fi

if [ ! -d "$HOME/bin/" ]; then
  mkdir "$HOME/bin/"
fi

if [ ! -f "$HOME/bin/oh-my-posh" ]; then
  curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/bin/oh-my-posh"
fi
