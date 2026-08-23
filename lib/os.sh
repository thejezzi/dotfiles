#!/usr/bin/env bash

has_command() {
  local cmd="$1"
  command -v "$cmd" &>/dev/null
}

# Run a command as root: directly when already root, via sudo otherwise.
as_root() {
  if ((EUID == 0)); then
    "$@"
  else
    sudo "$@"
  fi
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

is_fedora() {
  [[ -f "/etc/os-release" ]] && grep -qi '^ID=fedora$' /etc/os-release
}

current_login_shell() {
  local user
  user="$(id -un)"
  if is_macos; then
    dscl . -read "/Users/${user}" UserShell 2>/dev/null | awk '{print $2}'
  else
    getent passwd "${user}" 2>/dev/null | cut -d: -f7 ||
      awk -F: -v u="${user}" '$1 == u {print $7}' /etc/passwd
  fi
}
