# Hook contract tests

Regression tests for the hooks in `~/.claude/hooks`, the CC Safety Net rulebook, and ccx rule
scoping. Every assertion class exists because a real bug in this configuration went unnoticed for
months: the hooks were syntactically fine and silently did nothing.

```bash
cd ~/.claude
make test      # the contract suite
make doctor    # the suite, then cc-safety-net doctor + rule verify -g
```

Requires `jq`, `bash` 4+, `awk`, `git`. `cc-safety-net` is optional: without it, the rulebook class
skips instead of failing.

## Safety principle, non-negotiable

**Test the detectors, never the payloads.** Dangerous command strings only ever travel as JSON data
on a hook's stdin, or as an argument to `cc-safety-net explain`, which analyses a command without
executing it. Nothing destructive is ever run. Credential- and injection-shaped strings are assembled
at runtime from fragments so no literal lands in this file: the dotfiles repo is public, and the
`security-gate.sh` Write/Edit gate rejects files containing them.

## Assertion classes

| # | Class | Bug it would have caught |
|---|---|---|
| 1 | Field extraction | `post-bash-security.sh` read `.tool_output`, a field Claude Code never sends, so the secret scanner scanned an empty string. Same family: `cwd-profile.sh` reading `.cwd` instead of `.new_cwd`, and plugin hooks reading `.tool_result` instead of `.tool_response`. |
| 2 | Env contract | Three hooks read `CLAUDE_SESSION_ID`. The variable is `CLAUDE_CODE_SESSION_ID`; all three exited early on every invocation. |
| 3 | Exit-code hygiene | `set -euo pipefail` plus an unquoted, unbound `$1` aborted `security-gate.sh` before its later checks. Asserted on both real fixtures and a minimal `{}` payload. |
| 4 | Output shape | `SessionStart` hooks can only inject context through `hookSpecificOutput.additionalContext` with `hookEventName: "SessionStart"`. Anything else is discarded silently. |
| 5 | Rulebook conformance | Safety Net shape-validates the `tests[]` array in `rulebook.json` but never executes it. Untested, those fixtures are decorative comments. This class runs each one through `explain` and also asserts the `rtk` transparent wrapper still unwraps. |
| 6 | Rule scoping | `globs:` is not a valid ccx frontmatter key; a rule using it loads in *every* session instead of only where it applies. Asserts the key is gone and that each `paths:` pattern matches an in-scope file and rejects an out-of-scope one. |

## Fixtures

`fixtures/*.json` are hook payload envelopes whose `tool_response` objects were captured from real
transcripts under `~/.claude/projects/*/[0-9a-f]*.jsonl`, then sanitized: session IDs replaced with
an all-zero UUID, transcript paths rewritten to match. The response bodies themselves are unmodified
so the field shapes stay honest.

| Fixture | Source shape |
|---|---|
| `post-tool-use-bash.json` | Bash: `{stdout, stderr, interrupted, isImage, noOutputExpected}` |
| `post-tool-use-write.json` | Write: `{type, filePath, content, structuredPatch, originalFile, userModified}` |
| `pre-tool-use-bash.json` | PreToolUse Bash, `tool_input` only (no response yet) |
| `cwd-changed.json` | CwdChanged: carries both `cwd` and `new_cwd` |
| `session-start-compact.json` | SessionStart with `source: "compact"` |
| `pre-compact.json` | PreCompact with `trigger: "auto"` |

## Adding a test

Hooks run in a sandbox: `run_hook <hook> <payload> [VAR=value ...]` pipes the payload to stdin, runs
under a temporary `HOME` when the hook touches `~`, and exposes `HOOK_STDOUT`, `HOOK_STDERR`,
`HOOK_RC`. Assert with `pass`/`fail`/`skip`. Anything that would need a destructive command to prove
belongs in `rulebook.json`'s `tests[]` array, where class 5 will pick it up via `explain`.

## Known gap

The compaction pipeline (`PreCompact` → snapshot → `SessionStart:compact` → re-injection) is verified
here only at the unit level: each hook reads and writes what it should, given a synthetic activity
log. The end-to-end path has never run in a real session, and `session-logger.sh` (the sole producer
of `~/.claude/logs/activity-*.jsonl`) was deleted, so in practice `pre-compact-snapshot.sh` now
snapshots git state only. A real compaction is still the only way to prove the pipeline.
