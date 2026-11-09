---
name: dotfiles
description: Antoine's dotfiles, managed by chezmoi. How to change them, the source layout, his CLI tools. Use for dotfiles, chezmoi, or a change to a config file under ~ (shell, git, tmux, nvim, mise, OpenCode).
---

# Dotfiles

Antoine's config lives in a chezmoi source, `~/.local/share/chezmoi`, the git repo `aneveux/.dotfiles`. The repo is public: no secrets, tokens, internal hostnames or work-only content go in it. No template calls a secret manager and no file is encrypted.

## Edit model

- Change the source, never the live file under `~`: the next `chezmoi apply` overwrites it. `chezmoi managed` lists the targets, `chezmoi source-path <target>` gives a target's source.
- Edit sources with the edit and write tools. A policy denies you every chezmoi command except `diff`, `status`, `cat`, `managed` and `source-path`, so `chezmoi edit`, `add` and `apply` fail.
- Check with `chezmoi diff` (every pending change against the live files) and `chezmoi cat <target>` (one rendered target).
- Commit in the source with plain git: chezmoi's autoCommit only covers its own commands. Subjects start with a gitmoji, as in `git log`.
- Antoine reads `chezmoi diff`, runs `chezmoi apply` and pushes (autoPush is off). Say when a change waits for his apply. OpenCode reloads its config by itself after an apply.

## Layout

- Source names: `dot_` for a leading dot, `private_` for owner-only permissions, `executable_`, `symlink_`, and `.tmpl` for a Go template.
- Template data comes from `~/.config/chezmoi/chezmoi.toml`, written by `.chezmoi.toml.tmpl`: `.machine` (`flower` or `atuin`), `.email` and the monitor names. `.chezmoiignore` is a template too, and drops the laptop-only files on machines other than `flower`.
- `.chezmoiexternal.toml` pulls tpm, zinit and two binaries. `.chezmoiremove` lists targets to delete.
- `run_onchange_*` scripts run on apply when their rendered content changes. `run_onchange_after_mise-install.sh.tmpl` embeds a hash of the mise config, so editing `dot_config/mise/config.toml` runs `mise install --yes`.
- CLI tools come from mise. OpenCode is pinned there, and an upgrade is a deliberate version bump. System packages are listed in `packages.txt` and installed by hand.
- `dot_config/opencode/` is the OpenCode config: `AGENTS.md`, `opencode.jsonc.tmpl`, `plugins/`, `skills/`. The rendered `opencode.jsonc` must stay comment-free, so explanations go in template comments.
- `dot_claude/` is Claude Code's config. Leave it alone unless the task is about Claude Code. OpenCode reads nothing in it but the skills under its `skills/`.

## Toolset

nvim, Ghostty and tmux. In scripts, aliases and suggested commands, use tv (television) over fzf, zoxide over `cd`, jq for JSON, gh for GitHub, delta as the git pager and bat to view files.
