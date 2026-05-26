---
description: "PR review heuristics — what to check, how to communicate"
globs: "**"
---

# PR Reviews

- Logic correctness first, style second
- Check: error paths, edge cases, missing validation, resource leaks
- Flag: security (injection, auth bypass), performance (N+1, unbounded), concurrency
- Approve with nits if all issues are cosmetic
- Request changes only for correctness or security bugs
- Include a suggested fix with every non-trivial comment
- Never block on formatting if CI handles it
