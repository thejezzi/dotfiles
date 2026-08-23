#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

# 1. System packages (zsh, stow, tmux, fzf, ripgrep, fd, eza, bat, zoxide, ...)
install_tools

# 2. Link the dotfiles into $HOME (must happen before TPM so its plugin
#    installer sees the real ~/.tmux.conf)
apply_dotfiles
log_success "Dotfiles linked"

# 3. Shell ecosystem
ensure_oh_my_zsh
ensure_zsh_plugins

# 4. tmux ecosystem
ensure_tpm

# 5. Login shell
ensure_default_shell

log_success "Bootstrap complete"
