#!/usr/bin/env bash
# Git info for tmux status bar
# Shows: branch (normal repo) or repo:branch (worktree)
cd "$1" 2>/dev/null || exit 0

git rev-parse --is-inside-work-tree &>/dev/null || exit 0

branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
[ -z "$branch" ] && exit 0

git_dir=$(cd "$(git rev-parse --git-dir 2>/dev/null)" && pwd)
git_common_dir=$(cd "$(git rev-parse --git-common-dir 2>/dev/null)" && pwd)

if [ "$git_dir" != "$git_common_dir" ]; then
  repo_name=$(basename "$(dirname "$git_common_dir")")
  echo "${repo_name}:${branch}"
else
  echo "$branch"
fi
