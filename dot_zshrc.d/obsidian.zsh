#!/bin/bash 

OBSIDIAN_DIRECTORY="$HOME/notes"
NEXTCLOUD_OBSIDIAN_DIRECTORY="$HOME/Nextcloud/notes"
CURRENT_DIRECTORY="$PWD"

_ensure_nextcloud_dir() {
  if [[ ! -d "$NEXTCLOUD_OBSIDIAN_DIRECTORY" ]]; then
    echo "📁 Nextcloud notes directory does not exist. Creating..."
    mkdir -p "$NEXTCLOUD_OBSIDIAN_DIRECTORY" || {
      echo "❌ Failed to create $NEXTCLOUD_OBSIDIAN_DIRECTORY"
      return 1
    }
  fi
}

_sync_from_cloud() {
  _ensure_nextcloud_dir || return 1
  echo "☁️  Syncing from Nextcloud to Obsidian..."
  rsync -av --exclude='.git' "$NEXTCLOUD_OBSIDIAN_DIRECTORY/" "$OBSIDIAN_DIRECTORY/"
}

_pull_git() {
  echo "⏳ Pulling latest changes from Git..."
  cd "$OBSIDIAN_DIRECTORY" || { echo "❌ Failed to cd to $OBSIDIAN_DIRECTORY"; return 1; }

  if ! git pull --rebase; then
    echo "⚠️ Git pull failed, aborting sync."
    cd "$CURRENT_DIRECTORY"
    return 2
  fi

  cd "$CURRENT_DIRECTORY"
  return 0
}

_push_git() {
  cd "$OBSIDIAN_DIRECTORY" || { echo "❌ Failed to cd to $OBSIDIAN_DIRECTORY"; return 1; }

  # adding here to ensure catching deleted files 
  git add -A 

  if [[ -z $(git status --porcelain) ]]; then
    echo "😴 No changes to commit."
    cd "$CURRENT_DIRECTORY"
    return 0
  fi

  if git commit -m "📝 Quick obsidian notes update $(date '+%Y-%m-%d %H:%M:%S')"; then
    if git push; then
      echo "✅ Notes pushed to Git successfully!"
    else
      echo "⚠️ Commit done but failed to push."
      cd "$CURRENT_DIRECTORY"
      return 3
    fi
  else
    echo "⚠️ Nothing committed."
    cd "$CURRENT_DIRECTORY"
    return 4
  fi

  cd "$CURRENT_DIRECTORY"
  return 0
}

_sync_to_cloud() {
  _ensure_nextcloud_dir || return 1
  echo "📤 Syncing Obsidian to Nextcloud..."
  rsync -av --exclude='.git' "$OBSIDIAN_DIRECTORY/" "$NEXTCLOUD_OBSIDIAN_DIRECTORY/"
}

syncn() {
  _sync_from_cloud || return 1
  _pull_git || return 2
  _push_git || return 3
  _sync_to_cloud || return 4
  echo "🎉 Obsidian sync complete!"
}

