#!/bin/bash

function isAvailable() {
  local program="$1"
  if command -v "$program" $ >/dev/null; then
    echo 1
  else
    echo 0
  fi
}

if [ "$(isAvailable "asdf")" -eq 1 ]; then
  asdf plugin add java
  asdf plugin add cosign
  asdf plugin add helm
  asdf plugin add helmfile
  asdf plugin add jq
  asdf plugin add kotlin
  asdf plugin add maven
  asdf plugin add ruby
  asdf plugin add shellcheck
  asdf plugin add groovy
  asdf plugin add terraform
  asdf plugin add gradle
  asdf plugin add mvnd
  asdf plugin add kubectl
  asdf plugin add awscli
  asdf plugin add oc
  asdf plugin add rosa https://github.com/rh-mobb/asdf-rosa.git
  asdf plugin add pnpm
  asdf plugin add nodejs
  asdf plugin add yarn
  asdf plugin add bun
fi
