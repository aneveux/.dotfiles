# Bash Conventions

Use the **bark** plugin for CLI/script development:
- `/agent bash-developer` — write scripts
- `/agent bash-code-reviewer` — review
- `/agent bash-test-writer` — generate bats tests

Skills: `bash-style-guide`, `bash-tools`, `bash-patterns`, `bash-testing`, `bash-project-setup`

Key conventions:
- Always: `set -euo pipefail`
- gum for interactive UI, tv for fuzzy selection
- verb_noun function naming
- stderr for logs, stdout for data
- bats for testing

**CI/automation scripts**: no dependencies (no gum, tv, etc.). Plain bash, portable.
