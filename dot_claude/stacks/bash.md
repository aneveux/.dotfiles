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

## Gotchas

### gum spin cannot call bash functions
`gum spin -- my_function` silently fails — gum executes an external command, not a shell function.
**Fix**: run the function in a backgrounded subshell, use gum spin as visual-only:
```bash
my_spinner() {
    local title="$1"; shift
    local out=$(mktemp) err=$(mktemp)
    ( "$@" >"$out" 2>"$err" ) &
    local pid=$!
    gum spin --spinner dot --title "$title" -- bash -c "while kill -0 $pid 2>/dev/null; do sleep 0.1; done"
    wait "$pid"; local rc=$?
    cat "$err" >&2; cat "$out"; rm -f "$out" "$err"
    return "$rc"
}
```
