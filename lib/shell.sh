#!/usr/bin/env bash

# Makes shell_path the login shell for the current user. The caller chooses
# the shell; this module only implements the platform-specific mechanism.
ensure_default_shell() {
  local shell_path="$1"
  local current_shell
  local user

  if [[ -z "$shell_path" || ! -x "$shell_path" ]]; then
    log_error "Target login shell is missing or not executable: $shell_path"
    return 1
  fi

  current_shell="$(current_login_shell)"
  user="$(id -un)"

  if [[ "$current_shell" == "$shell_path" ]]; then
    log_info "${shell_path} is already the default shell for ${user}"
    return 0
  fi

  if ! grep -qx "$shell_path" /etc/shells 2>/dev/null; then
    log_info "Adding ${shell_path} to /etc/shells"
    printf '%s\n' "$shell_path" | as_root tee -a /etc/shells >/dev/null
  fi

  log_info "Setting default shell for ${user} to ${shell_path} (was: ${current_shell})"
  if is_macos; then
    chsh -s "$shell_path"
  else
    as_root chsh -s "$shell_path" "$user"
  fi

  if [[ "$(current_login_shell)" == "$shell_path" ]]; then
    log_success "Default shell is now ${shell_path} (takes effect on next login)"
  else
    log_error "Could not change default shell automatically"
    return 1
  fi
}
