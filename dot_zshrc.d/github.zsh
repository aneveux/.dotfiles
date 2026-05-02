_github_token_init() {
  export GITHUB_TOKEN="${GITHUB_TOKEN:-$(gh auth token)}"
  unfunction _github_token_init 2>/dev/null
}

precmd_functions+=(_github_token_init)
