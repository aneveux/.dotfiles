# CloudBees Development Context

## Jira tickets

Ticket keys like `BEE-1234`, `SECO-5678`, `CBCI-9012` refer to CloudBees Jira issues.

```
jira issue view BEE-1234              # TUI
jira issue view BEE-1234 --plain      # no TUI, pipe-friendly
jira issue view BEE-1234 --raw        # all fields as JSON
jira issue view BEE-1234 --comments N # fetch N comments
```

When a ticket is mentioned, pull it before acting on it.

## Repos

- `cloudbees/xxx` and `jenkinsci/xxx` → clone with `gh repo clone`.
- CI runs on Jenkins (dogfooding / gauntlet). To pull failing-CI logs from a PR, use `jk`.

## Stack

CloudBees CI = Jenkins core + CloudBees plugins, mostly Java.
