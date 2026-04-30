Fetch all review comments from the given GitHub PR, analyze them, and address each one.

## Steps

1. Run `gh pr view $ARGUMENTS --json reviews,comments,url,title,state` to get PR metadata
2. Run `gh api repos/{owner}/{repo}/pulls/{number}/comments` to get inline review comments
3. Run `gh api repos/{owner}/{repo}/issues/{number}/comments` to get conversation comments
4. For each comment/review: summarize what the reviewer is asking for
5. Present a structured list: reviewer, file, line, request
6. Ask me which comments to address (or all)
7. For each accepted comment: read the relevant file, implement the fix, and explain what changed

Use `@antoine-voice` for any PR reply text.
