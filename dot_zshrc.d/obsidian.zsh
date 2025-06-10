#!/bin/bash 

sync_notes() {
  local notes_dir="$HOME/notes"
  cd "$notes_dir" || { echo "❌ Failed to cd to $notes_dir"; return 1; }

  if git diff --quiet && git diff --cached --quiet; then
    echo "😴 No changes to commit in $notes_dir."
    return 0
  fi

  git add -A

  if git commit -m "📝 Quick obsidian notes update $(date '+%Y-%m-%d %H:%M:%S')"; then
    if git push; then
      echo "✅ Notes synced successfully!"
    else
      echo "⚠️ Commit done but failed to push!"
      return 2
    fi
  else
    echo "⚠️ Nothing committed (maybe no changes after all?)"
    return 3
  fi
}
