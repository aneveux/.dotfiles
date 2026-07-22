# Git Workflow — Personal Repos

## Commits

- One logical change per commit; imperative mood, subject under 72 chars, body only when non-obvious.
- Prefix the subject with a gitmoji glyph (the actual emoji, never `:code:`):
  ✨ feature · 🐛 fix · ♻️ refactor · 🧹 chore · 📝 docs · 👷 CI · 🔖 release · ✅ tests
- Never put Jira/ticket references in the message.

## Pushing

- Push to my own remotes (`aneveux`). Pull and rebase before pushing; never force-push.
- Default: solo repos commit straight to `master`. Ask whether to open a PR when CI must gate a
  risky change on a public repo, or when explicitly requested.

## Releases

- Release by bumping the version and pushing a semver `v*` tag; the tag-triggered CI workflow runs
  the release. Do not create the GitHub release by hand when such a workflow exists — use `/ship`
  only where there is no release workflow.
