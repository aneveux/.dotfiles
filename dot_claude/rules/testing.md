---
description: "Testing discipline — what to test, when to run"
globs: "**"
---

# Testing

- Run tests BEFORE committing, not just at the end
- Write the test FIRST when fixing a bug (proves the fix)
- Test public API, not private implementation
- One assertion per test method when practical
- Name tests: what_when_then or shouldDoX_whenY
- Mock at boundaries, not inline — prefer integration over unit when cheap
- Never skip a failing test — fix or delete
