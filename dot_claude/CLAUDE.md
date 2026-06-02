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

## Don'ts

- Don't explain code unless asked — just write it
- Don't add comments that restate what the code does
- Don't refactor outside the current task scope
- Don't suggest dependencies without justifying them
- Don't write wrapper functions that add no logic
- Don't use placeholder/TODO code — implement fully or skip
- Don't reorder, reformat, or add/remove blank lines unless requested — minimum viable diff only
- Don't silently apply noticed improvements — report them, then stop

## Session Naming

- Once session subject is clear (after 2-3 exchanges), run /name with short title
- Format: `[verb] [subject]` — max 50 chars, no date, no "Session:" prefix
- Action verb first: fix, add, refactor, update, research, debug, review
- If scope shifts significantly, re-rename before closing
- Do NOT ask for confirmation — just rename

## Compact Instructions

When compacting, preserve:
- Modified file list and paths being worked on
- Test commands run and their results
- Architectural decisions made this session
- Current task state and next steps
- Error messages actively being debugged

When compacting, drop:
- Files read for exploration but no longer relevant
- Resolved debug output and stack traces
- Long git log/diff output already processed
- Completed sub-tasks with no bearing on remaining work
- Large config files read for reference
