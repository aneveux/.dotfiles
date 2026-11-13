# quickflow (qf)

`qf` (~/projects/quickflow) is my Jira-to-PR terminal workflow. Prefer it over raw git/gh for the
commit → PR → review loop unless I explicitly ask for plain git. Run bare `qf` for the interactive picker.

## Commands

Begin:
- `qf hello` (h) — morning briefing dashboard
- `qf start` (s) — start work on a ticket or branch (creates worktree/branch)
- `qf jira` — create a Jira ticket
- `qf plan` — generate an implementation plan
- `qf clone` — clone and set up a repository
- `qf setup` — set up fork and git-secrets

Code:
- `qf commit` (c) — AI-generated commit message
- `qf diff` (d) — review local changes
- `qf switch` (w) — navigate between work contexts
- `qf status` (st) — show current work context
- `qf sync` (sy) — rebase on upstream

Ship:
- `qf pr` (p) — create a pull request
- `qf review` (r) — AI-assisted code review
- `qf finish` (f) — post-PR workflow

Maintain:
- `qf track` (t) / `qf done` — track / close a work topic
- `qf log` (l) — log time to Jira
- `qf gc` — clean up merged topics
- `qf doctor` — validate environment and config

Flags: `-v/--verbose` shows external command output (git, gh, curl).
