# Claude Code — Antoine's Preferences

## Identity

Antoine Neveux — Staff Software Engineer at CloudBees
Email: antoine@neveux.me | Work: aneveux@cloudbees.com
GitHub: aneveux | Timezone: Europe/Paris | Languages: French (native), English

## Communication

- Concise and direct — code examples over explanations
- Challenge my assumptions — don't be a yes man
- Don't over-explain obvious things
- Use `antoine-voice` skill for produced communication (Slack, emails, docs, PRs, READMEs). Fallback: `/humanizer`
- Claude's own conversational responses stay natural and direct

## Code Philosophy

- Functional programming, early returns, small functions
- Meaningful variable names over comments — no unnecessary comments
- Always: type definitions, error handling, tests for critical paths
- No over-engineering, no ignored errors
- Production-grade: proper logging, modern patterns

## Workflow Modes

- **Writing code**: write it directly with types and error handling
- **Reviewing**: logic and security first, style secondary, flag edge cases
- **Debugging**: show investigation, explain reasoning, suggest multiple solutions

## Environment

nvim • Kitty + tmux • Linux (Ubuntu/Manjaro) • chezmoi (dotfiles) • Git
Preferred: tv (not fzf) • zoxide (not cd) • jq • gh • delta • bat

## Automation Patterns

- Jira ticket mentioned (e.g. BEE-1234, SECO-5678) → CloudBees Jira tickets
  `jira issue view BEE-1234` (TUI) | `--plain` (no TUI) | `--raw` (all fields) | `--comments N` (fetch N comments)
- Git repo like `cloudbees/xxx` or `jenkinsci/xxx` → `gh repo clone`
- Commits, PRs, reviews, worktrees → use `qf` (~/projects/quickflow)
- Local code reviews (localreview.nvim) → use `/thorn:reviews` to find and process `.reviews.json` files
- Terminal workflows → use tmux
- Stash workflow (e.g. "address stash", "stash findings", "review stash") → read `STASH.md` + `.stash/items.json` in project root, present open items by priority, offer to address them

## Learning

- Go — adopt mentor approach when explaining Go concepts
- Frontend — not an expert, mentor approach (see stacks/frontend.md)

## Token Management

@RTK.md
