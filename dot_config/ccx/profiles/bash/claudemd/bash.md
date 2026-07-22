# Bash Conventions

Use the **bark** plugin for CLI/script development:
- `/agent bash-developer` — write scripts
- `/agent bash-code-reviewer` — review
- `/agent bash-test-writer` — generate bats tests

Skills: `bash-style-guide`, `bash-tools`, `bash-patterns`, `bash-testing`, `bash-project-setup`

Key conventions:
- Always: `set -euo pipefail`
- verb_noun function naming
- stderr for logs, stdout for data
- bats for testing, shellcheck for linting, shfmt for formatting
- Makefile as the task runner

For interactive/rich CLIs (gum, tv, etc.), see the `bash-cli` profile. CI/automation scripts must have
no such dependencies — plain, portable bash only.

## Docs

- Bash manual: https://www.gnu.org/software/bash/manual/bash.html
- ShellCheck: https://www.shellcheck.net/
- bats-core: https://bats-core.readthedocs.io/
