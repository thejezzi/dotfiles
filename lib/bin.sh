#!/usr/bin/env bash

install_bin() {
  local url="${1:-}"
  local name="${2:-${url##*/}}"
  local directory="${3:-$HOME/.local/bin}"
  local output=""

  if [[ -z "$url" ]]; then
    log_error "Usage: install_bin <url> [name] [dir]"
    return 1
  fi

  if [[ -z "$name" ]]; then
    log_error "Could not infer binary name from URL: $url"
    return 1
  fi

  mkdir -p "$directory"
  ensure_in_path "$directory" || true
  output="${directory}/${name}"

  if has_command curl; then
    curl -fsSL "$url" -o "$output"
  elif has_command wget; then
    wget -qO "$output" "$url"
  else
    log_error "curl or wget is required"
    return 1
  fi

  chmod +x "$output"
  log_success "Installed ${name} to ${output}"
}

ensure_in_path() {
  local directory="${1:-$HOME/.local/bin}"

  case ":$PATH:" in
    *":$directory:"*)
      log_info "${directory} is already in PATH"
      return 0
      ;;
  esac

  log_warn "${directory} is not in PATH"
  log_warn "Add this line to your shell config: export PATH=\"${directory}:\$PATH\""
  return 1
}

# Short name kept as a compatibility alias for callers that use ensure_path.
ensure_path() {
  ensure_in_path "$@"
}

# Uses a caller-provided installer URL so the utility module contains no
# provider-specific URLs. Usage: mise_use <version> <installer-url>.
mise_use() {
  local version="${1:-}"
  local installer_url="${2:-}"

  if [[ -z "$version" ]]; then
    log_error "Usage: mise_use <version> [installer-url]"
    return 1
  fi

  if ! has_command mise; then
    log_warn "Command mise could not be found"
    if [[ -z "$installer_url" ]]; then
      log_error "No mise installer URL was configured"
      return 1
    fi
    if ask "Install mise?"; then
      curl -fsSL "$installer_url" | sh
    else
      log_error "mise installation declined"
      return 1
    fi
  fi

  mise use -g "$version"
}
