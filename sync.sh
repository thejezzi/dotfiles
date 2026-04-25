#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v stow >/dev/null 2>&1; then
  printf '[ERROR] stow is not installed\n' >&2
  exit 1
fi

printf '[INFO] Applying dotfiles with stow from %s\n' "$SCRIPT_DIR"
stow --restow --adopt --target="$HOME" .
printf '[OK] Dotfiles linked\n'
