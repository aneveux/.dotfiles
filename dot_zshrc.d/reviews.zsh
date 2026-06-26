# Local PR review via diffview.nvim

# Full PR diff before pushing — branch point vs working tree (incl. uncommitted/unstaged)
prdiff() {
  local base
  base=$(git merge-base origin/HEAD HEAD 2>/dev/null) \
    || { echo "prdiff: cannot resolve origin/HEAD — is the remote set?" >&2; return 1; }
  nvim -c "DiffviewOpen $base"
}

# Followup diff — remote tip vs working tree (incl. uncommitted/unstaged unpushed work)
prfollow() {
  git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1 \
    || { echo "prfollow: no upstream for current branch" >&2; return 1; }
  nvim -c "DiffviewOpen @{upstream}"
}

# Commit-by-commit walk of the PR (committed history only)
prlog() {
  nvim -c "DiffviewFileHistory --range=origin/HEAD...HEAD"
}
