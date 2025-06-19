#!/bin/bash 

# === CONFIGURATION ===
OBSIDIAN_DIRECTORY="$HOME/notes"
NEXTCLOUD_OBSIDIAN_DIRECTORY="$HOME/Nextcloud/notes"
CURRENT_DIRECTORY="$PWD"

# === HELPERS ===

_ensure_nextcloud_dir() {
  if [[ ! -d "$NEXTCLOUD_OBSIDIAN_DIRECTORY" ]]; then
    echo "📁 Nextcloud notes directory does not exist. Creating..."
    mkdir -p "$NEXTCLOUD_OBSIDIAN_DIRECTORY" || {
      echo "❌ Failed to create $NEXTCLOUD_OBSIDIAN_DIRECTORY"
      return 1
    }
  fi
}

_git_commit_local_changes() {
  cd "$OBSIDIAN_DIRECTORY" || { echo "❌ Failed to cd to $OBSIDIAN_DIRECTORY"; return 1; }

  git add -A

  if [[ -z $(git status --porcelain) ]]; then
    echo "😴 No local changes to commit."
  else
    if git commit -m "📝 Local changes before pulling $(date '+%Y-%m-%d %H:%M:%S')"; then
      echo "✅ Local changes committed."
    else
      echo "⚠️ Failed to commit local changes."
      cd "$CURRENT_DIRECTORY"
      return 2
    fi
  fi

  cd "$CURRENT_DIRECTORY"
  return 0
}

_git_pull_rebase() {
  cd "$OBSIDIAN_DIRECTORY" || { echo "❌ Failed to cd to $OBSIDIAN_DIRECTORY"; return 1; }

  echo "⏳ Pulling latest from GitHub (rebase)..."
  if ! git pull --rebase; then
    echo "❌ Git pull resulted in conflicts. Resolve them manually."
    return 3
  fi

  echo "✅ Git pull successful."
  cd "$CURRENT_DIRECTORY"
  return 0
}

_rsync_from_nextcloud_and_check_git_changes() {
  _ensure_nextcloud_dir || return 1

  echo "☁️  Syncing from Nextcloud to local..."

  # Perform the actual sync
  rsync -av --exclude='.git' "$NEXTCLOUD_OBSIDIAN_DIRECTORY/" "$OBSIDIAN_DIRECTORY/"

  # Check if this changed anything in Git
  cd "$OBSIDIAN_DIRECTORY" || { echo "❌ Failed to cd to $OBSIDIAN_DIRECTORY"; return 1; }

  if [[ -n $(git status --porcelain) ]]; then
    echo "⚠️ Changes detected after syncing from Nextcloud:"
    git status --short
    echo "🛑 Aborting so you can review these changes manually."
    return 4
  fi

  echo "✅ No changes from Nextcloud."
  cd "$CURRENT_DIRECTORY"
  return 0
}

_rsync_to_nextcloud() {
  _ensure_nextcloud_dir || return 1

  echo "📤 Syncing to Nextcloud (repository is source of truth)..."
  rsync -av --delete --exclude='.git' "$OBSIDIAN_DIRECTORY/" "$NEXTCLOUD_OBSIDIAN_DIRECTORY/"
  echo "✅ Sync to Nextcloud complete."
  return 0
}

_git_push() {
  cd "$OBSIDIAN_DIRECTORY" || { echo "❌ Failed to cd to $OBSIDIAN_DIRECTORY"; return 1; }

  echo "🚀 Pushing to GitHub..."
  if git push; then
    echo "✅ Git push successful!"
  else
    echo "⚠️ Git push failed. Please resolve manually."
    return 5
  fi

  cd "$CURRENT_DIRECTORY"
  return 0
}

# === MAIN SYNC FUNCTION ===

syncn() {
  echo "🚀 Starting Obsidian sync..."

  _git_commit_local_changes || return 1
  _git_pull_rebase || return 2
  _rsync_from_nextcloud_and_check_git_changes || return 3
  _rsync_to_nextcloud || return 4
  _git_push || return 5

  echo "🎉 Obsidian sync complete!"
  return 0
}

