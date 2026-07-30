# SonarQube CLI (`sonar`)

The `sonar` binary talks to a self-hosted **SonarQube Server** (CloudBees). Auth lives in the OS
keychain — never pass, set, or print tokens, and never touch `SONARQUBE_CLI_*` env vars.

## When to use it

- **Only on an explicit request.** `sonar` is an on-demand tool — never run it proactively as part
  of another task.

## What works on Server (this connection)

- `sonar analyze secrets <paths...>` — local secrets scan, runs offline. Exit code `51` = secret
  found, `0` = clean.
- `sonar list issues -p <project-key> [--severities ...] [--statuses ...] --format json` — query
  server-side issues.
- `sonar list projects [-q <query>]` — find project keys (always JSON; it has no `--format` flag).
- `sonar api <METHOD> <endpoint>` — raw authenticated Web API calls for anything the above can't
  express.

Project key is auto-detected from `sonar-project.properties`, so `-p` is often optional. `list
issues` defaults to JSON and also takes `--format table|csv|toon`; `list projects` is always JSON.

## Do not

- Don't suggest or run `sonar analyze` (bare), `sonar analyze agentic`, or `sonar remediate` — those
  are **SonarQube Cloud only** and no-op on this Server connection.
- Don't run `sonar integrate`, `sonar config`, or `sonar system reset` — they mutate global state
  and installed integrations.
