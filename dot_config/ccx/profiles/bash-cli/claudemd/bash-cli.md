# Interactive Shell Tooling

For user-facing, interactive shell tools (as opposed to CI/automation scripts, which stay dependency-free).

- **gum** — prompts, spinners, styled output, selection menus.
- **tv** (television) — fuzzy selection, not fzf.
- **zoxide** — directory jumping. **jq** — JSON. **bat** — paging. **delta** — diffs.

## Gotchas

- `gum spin -- my_function` silently fails — gum runs an external command, not a shell function. Run
  the function in a backgrounded subshell and use `gum spin` as a visual-only wait. See the
  `bash-patterns` skill for the wrapper.

## Docs

- gum: https://github.com/charmbracelet/gum
