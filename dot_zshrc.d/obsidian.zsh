#!/bin/bash 

sync_notes() {
  local notes_dir="$HOME/notes"
  local cur_dir="$PWD"
  
  cd "$notes_dir" || { echo "❌ Failed to cd to $notes_dir"; return 1; }

  echo "⏳ Pulling latest changes..."
  if ! git pull --rebase; then
    echo "⚠️ Failed to pull latest changes, aborting sync."
    cd "$cur_dir"
    return 1
  fi

  if git diff --quiet && git diff --cached --quiet; then
    echo "😴 No changes to commit in $notes_dir."
    cd "$cur_dir"
    return 0
  fi

  git add -A

  if git commit -m "📝 Quick obsidian notes update $(date '+%Y-%m-%d %H:%M:%S')"; then
    if git push; then
      echo "✅ Notes synced successfully!"
    else
      echo "⚠️ Commit done but failed to push!"
      cd "$cur_dir"
      return 2
    fi
  else
    echo "⚠️ Nothing committed (maybe no changes after all?)"
    cd "$cur_dir"
    return 3
  fi

  cd "$cur_dir"
}
