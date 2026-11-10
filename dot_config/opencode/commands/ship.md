---
description: Commit, bump the version, tag and push a release of a personal repo (optional version)
---
Ship the current changes of this repo as a release. Personal repos only: if `origin` or `upstream` is on GitHub under cloudbees, jenkinsci or jenkins-infra, stop and say so.

Version asked for, if any: $ARGUMENTS

1. Run `git status` and `git diff --stat` to see what's pending.
2. Commit any uncommitted change, with a message written with the `antoine-voice` skill.
3. Find the current version: the latest `v*` tag, and the version markers in the code (`pom.xml`, `package.json`, `VERSION` and the like). Suggest the next semver from the commits since that tag.
4. Use the version given above if there is one. Otherwise ask me to confirm the tag before going further.
5. If the repo has version markers, bump them to that version and commit the bump.
6. Tag and push: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`, `git push`, then `git push origin vX.Y.Z`.
7. If a workflow in `.github/workflows/` runs on pushed `v*` tags, it makes the release: don't create one by hand, and show the URL of its run. Otherwise run `gh release create vX.Y.Z --generate-notes` and show the release URL.
