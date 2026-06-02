---
description: "Hard constraints and process invariants — never-break rules that resist context decay"
---

# Session Invariants

## Data Safety
- Never store secrets (API keys, passwords, tokens) in source files
- Never force-push to any branch, under any circumstances
- Never run DROP, TRUNCATE, or DELETE without WHERE clause
- Never commit .env, .pem, credentials, or private key files

## Process Safety
- Never skip pre-commit hooks (no --no-verify)
- Never amend a pushed commit
- Run tests after significant code changes, not just at the end
- Read a file before modifying it

## Scope Safety
- Never refactor code outside the current task — capture it with `stash` instead
- State rationale before adding any dependency
- One logical change per commit
- Every changed line must trace to the request — see rules/minimal-changes.md
