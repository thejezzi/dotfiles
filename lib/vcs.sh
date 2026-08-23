#!/usr/bin/env bash

# Pulls a repository only when its working tree is clean. Local modifications
# are never overwritten by the bootstrap.
update_repo() {
  local directory="$1"
  local label="${2:-$1}"

  if [[ -n "$(git -C "$directory" status --porcelain 2>/dev/null)" ]]; then
    log_info "${label}: local changes present, skipping update"
    return 0
  fi

  git -C "$directory" pull --ff-only -q || log_warn "${label}: update failed"
}

# Clones a repository when absent, updates clean clones and leaves existing
# non-git directories untouched. URL and destination are caller-owned data.
clone_or_update() {
  local url="$1"
  local destination="$2"
  local label="${3:-$destination}"

  if [[ -d "$destination/.git" ]]; then
    update_repo "$destination" "$label"
    return 0
  fi

  if [[ -e "$destination" ]]; then
    log_warn "${label}: destination exists but is not a git clone, skipping"
    return 0
  fi

  log_info "Installing ${label}"
  git clone -q --depth 1 "$url" "$destination"
}
