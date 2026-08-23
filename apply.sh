#!/usr/bin/env bash

set -euo pipefail

DOTFILES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${DOTFILES_ROOT}/manifest"

# shellcheck source=lib.sh
source "${DOTFILES_ROOT}/lib.sh"

TOOLS_MANIFEST="${MANIFEST_DIR}/tools.tsv"
ZSH_PLUGINS_MANIFEST="${MANIFEST_DIR}/zsh-plugins.tsv"
REPOS_MANIFEST="${MANIFEST_DIR}/repos.tsv"

manifest_repo_url() {
  local name="$1"
  manifest_lookup "$REPOS_MANIFEST" "$name" 2
}

install_tools() {
  local -a missing=()
  local command_name fedora_package macos_package package

  if is_macos && ! has_command brew; then
    ensure_brew "$(manifest_repo_url brew-installer)"
  fi

  while IFS=$'\t' read -r command_name fedora_package macos_package; do
    if has_command "$command_name"; then
      continue
    fi

    if is_macos; then
      package="$macos_package"
    else
      package="$fedora_package"
    fi

    if [[ -z "$package" ]]; then
      log_error "No package mapping for command: ${command_name}"
      return 1
    fi
    missing+=("$package")
  done < <(manifest_rows "$TOOLS_MANIFEST")

  if ((${#missing[@]} == 0)); then
    log_info "All manifest tools already installed."
    return 0
  fi

  system_install "${missing[@]}"
}

ensure_oh_my_zsh() {
  local directory="$HOME/.oh-my-zsh"
  local url
  url="$(manifest_repo_url oh-my-zsh)"
  if [[ -z "$url" ]]; then
    log_error "Missing manifest entry: oh-my-zsh"
    return 1
  fi

  clone_or_update "$url" "$directory" "oh-my-zsh"
}

ensure_zsh_plugins() {
  local plugins_directory="$HOME/.oh-my-zsh/custom/plugins"
  local plugin_name repository destination

  mkdir -p "$plugins_directory"
  while IFS=$'\t' read -r plugin_name repository; do
    destination="${plugins_directory}/${plugin_name}"
    clone_or_update "$repository" "$destination" "$plugin_name" ||
      log_warn "install failed for ${plugin_name}"
  done < <(manifest_rows "$ZSH_PLUGINS_MANIFEST")
  log_success "zsh plugins installed"
}

ensure_tpm() {
  local directory="$HOME/.tmux/plugins/tpm"
  local url
  url="$(manifest_repo_url tpm)"
  if [[ -z "$url" ]]; then
    log_error "Missing manifest entry: tpm"
    return 1
  fi

  clone_or_update "$url" "$directory" "TPM"

  log_info "Installing tmux plugins"
  if "$directory/bin/install_plugins"; then
    log_success "tmux plugins installed"
  else
    log_warn "tmux plugin install reported errors"
  fi
}

install_tools
apply_dotfiles "$DOTFILES_ROOT" common
log_success "Dotfiles linked"

ensure_oh_my_zsh
ensure_zsh_plugins
ensure_tpm
ensure_default_shell "$(command -v zsh)"

log_success "Bootstrap complete"
