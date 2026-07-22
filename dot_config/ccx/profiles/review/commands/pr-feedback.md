---
description: Fetch and address review comments on a GitHub PR
argument-hint: "[pr-number|url]"
allowed-tools: Bash(gh *), Read, Edit, Write, Grep, Glob, Task
---

Address the review feedback on the pull request in `$ARGUMENTS`.

## Steps

1. `gh pr view $ARGUMENTS --json reviews,comments,url,title,state,headRefName` for PR metadata.
2. Inline review comments: `gh api repos/{owner}/{repo}/pulls/{number}/comments`.
3. Conversation comments: `gh api repos/{owner}/{repo}/issues/{number}/comments`.
4. Present a structured list — reviewer, file, line, and what they're asking for. Group duplicates.
5. Ask which comments to address (or all).
6. For each accepted comment: read the file, implement the fix, explain what changed. Delegate to a
   specialized agent when the change is substantial and one fits the stack.
7. Draft any PR reply text with the `antoine-voice` skill and write it into
   `./review-feedback-pr-<number>.md` as *suggested* replies. Do **not** post replies — posting
   happens only on my explicit, in-the-moment instruction.
