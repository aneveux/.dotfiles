# Jenkins Logs via jk

Use `jk` to retrieve build logs. Always set `JK_INSTANCE` to select the instance
and pass `--raw` for plain text output suitable for AI consumption.

```bash
# URR pull requests → gauntlet3, path: builders/URR-pr-builder/PR-<number>
JK_INSTANCE=gauntlet3 jk logs builders/URR-pr-builder/PR-12345 --raw

# CloudBees plugins/components → dogfooding, path: CBCI/<plugin-name>/<branch>
JK_INSTANCE=dogfooding jk logs CBCI/operations-center/master --raw

# Specific build number (omit for lastBuild)
JK_INSTANCE=dogfooding jk logs CBCI/operations-center/master 42 --raw

# Pipe for triage
JK_INSTANCE=gauntlet3 jk logs builders/URR-pr-builder/PR-12345 --raw | grep -i "error\|failed"
```

Rules: always `JK_INSTANCE=` (never `jk use`), always `--raw`.
