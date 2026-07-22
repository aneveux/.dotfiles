# Git Workflow — Shared / Work Repos

- One logical change per commit; imperative subject under 72 chars, body when non-obvious.
- Push to my fork (remote `aneveux`), never to `origin` (the CloudBees remote).
- Always pull and rebase before pushing on shared branches; never force-push.
- Work on feature branches or worktrees, never long-lived stashes.
- Branch names: `JIRA-1234-short-description` (e.g. `BEE-1234-fix-auth-bug`).
- Do not add Jira ticket references to commit messages — a git hook injects them automatically.
- Open PRs against `origin`; rebase onto the upstream default branch before requesting review.
