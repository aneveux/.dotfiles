#!/bin/bash

DESTINATION=~/.tmux/plugins/tpm
GIT_CMD=$(command -v git)

if [ ! -d "$DESTINATION" ]; then
  if [ -z "$GIT_CMD" ]; then
    echo "Git is not installed."
    exit 1
  fi
  git clone https://github.com/tmux-plugins/tpm "$DESTINATION"
fi
