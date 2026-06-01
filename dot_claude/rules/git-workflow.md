---
description: "Git workflow constraints — branch hygiene, commit discipline, tooling preferences"
globs: "**"
---

# Git Workflow

- Default workflow tools: `qf commit` (AI commit messages), `qf pr` (AI PR descriptions), `qf review`, `qf start` (worktrees), `qf clone` — suggest these unless user explicitly asks for raw git/gh
- Commit messages: imperative mood, <72 chars subject, body when non-obvious
- One logical change per commit
- Never force-push to any branch
- Always pull before push on shared branches
- Feature branches: short-lived, rebase onto main before merge
- Tag releases with semver (vX.Y.Z)
- Worktrees for parallel work — never stash long-lived changes
