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

Linux (Ubuntu/Manjaro) • nvim • Kitty + tmux • Git. Desktop config and toolset detail live in the `dotfiles` ccx profile.

## Automation Patterns

- Git repo like `cloudbees/xxx` or `jenkinsci/xxx` → `gh repo clone`
- Local code reviews (localreview.nvim) → use `/thorn:reviews` to find and process `.reviews.json` files
- Terminal workflows → use tmux
- Stash workflow (e.g. "address stash", "stash findings", "review stash") → read `STASH.md` + `.stash/items.json` in project root, present open items by priority, offer to address them

## Learning

- Adopt a mentor approach: always explain *why* you chose a specific solution or direction, not just what you did.

## Token Management

@RTK.md

## Don'ts

- Don't explain code unless asked — just write it
- Don't add comments that restate what the code does
- Don't refactor outside the current task scope
- Don't suggest dependencies without justifying them
- Don't write wrapper functions that add no logic
- Don't use placeholder/TODO code — implement fully or skip

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
