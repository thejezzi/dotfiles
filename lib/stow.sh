#!/usr/bin/env bash

apply_dotfiles() {
  local dotfiles_root="$1"
  local package="$2"

  migrate_stow_links "$dotfiles_root" "$package"

  log_info "Applying ${package} dotfiles with stow"
  # --no-folding keeps ~/.config and ~/.local as real directories. Otherwise
  # fresh machines can end up writing application data into the repository.
  stow --dir="${dotfiles_root}/packages" \
    --target="$HOME" \
    --restow \
    --no-folding \
    --override='^.*' \
    "$package"
}

migrate_stow_links() {
  local dotfiles_root="$1"
  local package="$2"
  local package_dir="${dotfiles_root}/packages/${package}"
  local source_file=""
  local relative_path=""
  local destination=""
  local removed=0

  if [[ ! -d "$package_dir" ]]; then
    log_warn "Package directory missing, skipping migration: $package_dir"
    return 0
  fi

  while IFS= read -r -d '' source_file; do
    relative_path="${source_file#"$package_dir"/}"
    destination="$HOME/$relative_path"

    if [[ -L "$destination" && ! -e "$destination" ]]; then
      log_info "Removing stale symlink: $destination"
      rm "$destination"
      removed=$((removed + 1))
      continue
    fi

    if [[ -e "$destination" && ! -L "$destination" ]]; then
      log_warn "Existing real file blocks stow: $destination"
    fi
  done < <(find "$package_dir" \( -type f -o -type l \) -print0)

  if ((removed > 0)); then
    log_success "Migrated $removed stale symlink(s) for package '$package'"
  fi
}
