Commit current changes, tag, push, and create a GitHub release.

## Steps

1. Run `git status` and `git diff --stat` to see what's pending
2. If there are uncommitted changes: compose a conventional commit message and commit
3. Determine the version: check the latest git tag, look for version bumps in code (package.json, pom.xml, VERSION, etc.), and suggest the next version
4. Ask me to confirm the version tag before proceeding
5. Create the git tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
6. Push branch and tags: `git push && git push --tags`
7. Create GitHub release: `gh release create vX.Y.Z --generate-notes`
8. Show the release URL

If $ARGUMENTS contains a version (e.g., "1.2.0"), use that instead of auto-detecting.
