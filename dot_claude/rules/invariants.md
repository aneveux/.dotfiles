---
description: "Hard constraints and process invariants — never-break rules that resist context decay"
---

# Session Invariants

## Data Safety
- Never store secrets (API keys, passwords, tokens) in source files
- Never force-push to main or master
- Never run DROP, TRUNCATE, or DELETE without WHERE clause
- Never commit .env, .pem, credentials, or private key files

## Code Safety — Java
- No empty catch blocks — log or rethrow, never swallow
- No System.out.println for logging — use SLF4J
- No raw types — always parameterize generics
- No string concatenation in SQL — use PreparedStatement or JPA named parameters

## Process Safety
- Never skip pre-commit hooks (no --no-verify)
- Never amend a pushed commit
- Run tests after significant code changes, not just at the end
- Read a file before modifying it

## Scope Safety
- Never refactor code outside the current task — note it for later
- State rationale before adding any dependency
- One logical change per commit
