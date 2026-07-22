---
description: Commit, tag, push, and create a GitHub release (personal repos only)
argument-hint: "[version]"
allowed-tools: Bash(git *), Bash(gh *)
---

Ship the current changes as a release. Personal-repo workflow only — do not use on CloudBees repos.

## Steps

1. `git status` and `git diff --stat` to see what's pending.
2. If there are uncommitted changes, compose a gitmoji commit message (per the git-perso rules) and commit.
3. Determine the version: check the latest git tag and any version markers in code (`pom.xml`, `package.json`, `VERSION`). Suggest the next semver.
4. Ask me to confirm the tag before proceeding. If `$ARGUMENTS` contains a version, use that and skip the prompt.
5. Prefer a tag-triggered release workflow if the repo has one: push a `vX.Y.Z` tag and let CI release. Only fall back to manual release when no such workflow exists.
6. Manual fallback: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`, then `git push && git push --tags`, then `gh release create vX.Y.Z --generate-notes`.
7. Show the release URL.
