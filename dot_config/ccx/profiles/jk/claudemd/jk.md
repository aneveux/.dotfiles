# jk — Jenkins Terminal Navigator

`jk` fetches Jenkins build info and logs. When CI on a PR fails (usually on dogfooding or gauntlet),
use `jk` to pull the logs instead of asking me to paste them.

## Instances

- `dogfooding` — https://dogfooding.cloudbees.com/dogfooding-controller-1
- `gauntlet3` — https://gauntlet-3.cloudbees.com/cbci

**Select the instance per-command with the `JK_INSTANCE` env var — don't run `jk use`.** `JK_INSTANCE`
overrides the active instance for a single invocation without touching shared state, so it's safe and
explicit. (`jk use <instance>` mutates my global default; `jk instances` lists what's configured.)

## Job paths

The path is a single slash-separated argument; each segment is a Jenkins folder/job level. The build
number is an optional trailing argument — omit it to get `lastBuild`. Folder layout differs per instance:

- gauntlet3: `builders/<pr-builder>/PR-<n>` (e.g. `builders/URR-pr-builder/PR-20920`)
- dogfooding: `CBCI/operations-center/PR-<n>` (e.g. `CBCI/operations-center/PR-853`)

## Failing-CI-on-a-PR recipe

1. Identify the failing job/build from the PR checks (or `JK_INSTANCE=<inst> jk jobs` /
   `JK_INSTANCE=<inst> jk builds <job-path>`).
2. Pull the raw log of the PR job's last build:

   ```bash
   # gauntlet 3 — URR PR builder, PR #20920
   JK_INSTANCE=gauntlet3 jk logs builders/URR-pr-builder/PR-20920 --raw

   # dogfooding — operations-center, PR #853
   JK_INSTANCE=dogfooding jk logs CBCI/operations-center/PR-853 --raw
   ```

   Append a build number to target a specific run instead of the latest:

   ```bash
   JK_INSTANCE=gauntlet3 jk logs builders/URR-pr-builder/PR-20920 42 --raw
   ```

3. Grep the raw output for the failure.
4. Test results and recent builds:

   ```bash
   JK_INSTANCE=dogfooding jk tests CBCI/operations-center/PR-853 --raw
   JK_INSTANCE=gauntlet3 jk builds builders/URR-pr-builder/PR-20920 --raw
   ```

Most commands support `--raw` (TSV/plain, pipe-friendly) and `--json` (Jenkins API). Always prefer
`--raw` when reading logs into context.
