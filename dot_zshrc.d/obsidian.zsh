#!/usr/bin/env zsh
OBSIDIAN_DIR="$HOME/notes"
NEXTCLOUD_DIR="$HOME/Nextcloud/notes"
WORKSPACE_REL=".obsidian/workspace.json"
_has_gum() { command -v gum >/dev/null 2>&1 }
_log() {
  local level="$1"; shift
  local gum_level
  case "$level" in
    ok|success) gum_level="info" ;;
    warn|warning) gum_level="warn" ;;
    error|err) gum_level="error" ;;
    debug|info|fatal|none) gum_level="$level" ;;
    *) gum_level="info" ;;
  esac
  if _has_gum; then
    gum log --structured --level "$gum_level" "$@"
  else
    local msg="$1"; shift
    printf "[%s] %s\n" "${gum_level:u}" "$msg"
  fi
}
_run() {
  local title="$1"; shift; shift
  if _has_gum; then
    gum spin --title "$title" -- "$@"
  else
    _log info "$title"; "$@"
  fi
}
_require_git_repo() {
  [[ -d "$OBSIDIAN_DIR/.git" ]] || { _log error "Not a git repo" dir "$OBSIDIAN_DIR"; return 1; }
}
_ensure_nextcloud_dir() {
  [[ -d "$NEXTCLOUD_DIR" ]] || { _log warn "Creating Nextcloud notes directory" dir "$NEXTCLOUD_DIR"; mkdir -p "$NEXTCLOUD_DIR" || { _log error "Failed to create Nextcloud directory" dir "$NEXTCLOUD_DIR"; return 1; }; }
}
_git_dirty() { [[ -n "$(git -C "$OBSIDIAN_DIR" status --porcelain 2>/dev/null)" ]] }
_git_commit_if_needed() {
  git -C "$OBSIDIAN_DIR" add -A
  if _git_dirty; then
    git -C "$OBSIDIAN_DIR" commit -m "notes: local changes $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null
    _log ok "Committed local changes"
  else
    _log info "No local changes"
  fi
}
_git_pull_rebase() { _run "Pulling from remote (rebase)" -- git -C "$OBSIDIAN_DIR" pull --rebase --autostash }
_rsync_from_nextcloud() {
  _ensure_nextcloud_dir || return 1
  _run "Sync from Nextcloud" -- rsync -a --exclude ".git" --exclude "$WORKSPACE_REL" "$NEXTCLOUD_DIR/" "$OBSIDIAN_DIR/"
  if _git_dirty; then
    git -C "$OBSIDIAN_DIR" add -A
    git -C "$OBSIDIAN_DIR" commit -m "notes: import changes from Nextcloud $(date '+%Y-%m-%d %H:%M:%S')" >/dev/null
    _log ok "Imported Nextcloud changes into git"
  else
    _log info "No changes from Nextcloud"
  fi
}
_seed_workspace_to_nextcloud_once() {
  local src="$OBSIDIAN_DIR/$WORKSPACE_REL"
  local dst="$NEXTCLOUD_DIR/$WORKSPACE_REL"
  if [[ -f "$src" && ! -f "$dst" ]]; then
    mkdir -p "${dst:h}"
    cp -f "$src" "$dst"
    _log ok "Seeded workspace.json to Nextcloud" path "$dst"
  fi
}
_rsync_to_nextcloud() {
  _ensure_nextcloud_dir || return 1
  _run "Sync to Nextcloud" -- rsync -a --delete --exclude ".git" --exclude "$WORKSPACE_REL" "$OBSIDIAN_DIR/" "$NEXTCLOUD_DIR/"
  _seed_workspace_to_nextcloud_once
}
_git_push() { _run "Pushing to remote" -- git -C "$OBSIDIAN_DIR" push }
syncn() {
  _log info "Starting Obsidian sync"
  _require_git_repo || return 1
  _ensure_nextcloud_dir || return 1
  _git_commit_if_needed || return 1
  _git_pull_rebase    || { _log error "Git pull failed (conflicts?)"; return 2; }
  _rsync_from_nextcloud || return 3
  _rsync_to_nextcloud   || return 4
  _git_push             || return 5
  _log ok "Obsidian sync complete"
}
