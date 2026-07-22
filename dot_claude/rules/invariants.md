# Session Invariants

Hard constraints that never bend, regardless of task or project.

- Never store secrets (API keys, passwords, tokens) in source files
- Never commit `.env`, `.pem`, credentials, or private key files
- Never force-push to any branch, under any circumstances
- Run tests after significant code changes, not just at the end
- Read a file before modifying it
