---
description: Query and triage SonarQube Server issues for a project
argument-hint: "[project-key]"
allowed-tools: Bash(sonar list *), Bash(sonar api *), Read, Grep, Glob
---

Query server-side issues from SonarQube and present a triage summary. Read-only.

## Steps

1. Resolve the project key from `$ARGUMENTS`. If empty, try `sonar-project.properties`
   (`sonar.projectKey`) in the repo root. If still unknown, run `sonar list projects` (JSON, filter
   with `-q <query>`) and ask which one — do not guess.
2. Run `sonar list issues -p <project-key> --format json`. Narrow with `--severities` /
   `--statuses` only if the user asked (e.g. `--severities BLOCKER,HIGH`,
   `--statuses OPEN,CONFIRMED`). Note: severity values depend on server mode (MQR:
   INFO/LOW/MEDIUM/HIGH/BLOCKER; Standard: INFO/MINOR/MAJOR/CRITICAL/BLOCKER).
3. Group findings by severity, highest first. For each, cite `file:line`, the rule, and the message.
4. Present a compact triage summary: counts per severity, then the actionable items. For deeper
   detail on a specific issue or rule, use `sonar api GET <endpoint>`.
5. Read-only: do **not** remediate, edit files, or post anything back to the server.
