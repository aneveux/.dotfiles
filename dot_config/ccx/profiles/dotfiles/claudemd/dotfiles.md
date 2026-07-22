# Dotfiles & Desktop Environment

Local config is managed with **chezmoi**. When I ask to change local/desktop config, edit the chezmoi
source, not the live target.

- Source lives in the chezmoi dir; apply with `chezmoi apply`, edit with `chezmoi edit <target>`.
- Never hand-edit a file under `~` that chezmoi manages — the change is lost on next `apply`. Check
  `chezmoi managed` when unsure.
- Preview changes with `chezmoi diff` before applying.

## Toolset

- Editor: **nvim**
- Terminal: **Kitty** + **tmux**
- OS: Linux (Ubuntu / Manjaro)
- Fuzzy finder: **tv** (television), not fzf
- Directory jump: **zoxide**, not plain `cd`
- JSON: **jq** · GitHub: **gh** · Git diff pager: **delta** · File viewer: **bat**

Prefer these over their defaults when scripting or suggesting commands.
