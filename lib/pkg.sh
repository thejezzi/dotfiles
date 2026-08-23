#!/usr/bin/env bash

is_pkg_installed() {
  local package="$1"
  if is_macos; then
    brew list --versions "$package" >/dev/null 2>&1
  elif is_fedora; then
    rpm -q "$package" >/dev/null 2>&1
  else
    return 1
  fi
}

ensure_brew() {
  local installer_url="${1:-}"

  if has_command brew; then
    return 0
  fi

  log_warn "Homebrew is required but was not found"
  if [[ -z "$installer_url" ]]; then
    log_error "No Homebrew installer URL was configured"
    return 1
  fi
  if ! ask "Autoinstall Homebrew?"; then
    log_error "Homebrew installation declined"
    return 1
  fi

  /bin/bash -c "$(curl -fsSL "$installer_url")"

  # The installer may update shell startup files, but that does not affect
  # this already-running process. Add the common Homebrew locations now.
  local candidate
  for candidate in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$candidate" ]]; then
      export PATH="${candidate%/*}:$PATH"
      return 0
    fi
  done

  log_error "Homebrew installation finished, but brew is not on PATH"
  return 1
}

# Installs package names supplied by the caller. This module knows package
# managers, but not which packages the dotfiles happen to need.
system_install() {
  local -a pm=()
  local -a missing=()
  local package

  if is_macos; then
    pm=(brew install)
  elif is_fedora; then
    pm=(as_root dnf install -y)
  else
    log_error "OS not supported"
    return 1
  fi

  for package in "$@"; do
    if ! is_pkg_installed "$package"; then
      missing+=("$package")
    fi
  done

  if ((${#missing[@]} == 0)); then
    log_info "All requested packages are already installed."
    return 0
  fi

  log_info "Installing: ${missing[*]}"
  "${pm[@]}" "${missing[@]}"
  log_success "Installed requested packages."
}
