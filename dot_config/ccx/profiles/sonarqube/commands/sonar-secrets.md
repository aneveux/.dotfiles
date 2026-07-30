---
description: Scan files for hardcoded secrets with the SonarQube CLI
argument-hint: "[path]"
allowed-tools: Bash(sonar analyze secrets *), Bash(git *), Read
---

Scan for hardcoded secrets using `sonar analyze secrets`. Runs locally, no server call.

## Steps

1. Resolve the scan target from `$ARGUMENTS`. If empty, default to the changed set:
   `git diff --name-only --diff-filter=ACM` (staged + unstaged). If that's empty too, scan the repo
   root `.`.
2. Run `sonar analyze secrets <paths...>` on the resolved paths.
3. Interpret the exit code: `51` = at least one secret found, `0` = clean. Anything else = tool
   error — surface it, don't retry blindly.
4. Summarize each finding by `file:line` with the secret type. **Do not print the secret value.**
5. Do **not** auto-remediate, rewrite files, or scrub history. Report findings and stop — removal is
   the user's call.
