#!/usr/bin/env bash
# smoke.sh — platform-agnostic fresh-machine smoke test for the dotfiles.
#
# Runs against an empty HOME on a system that has nothing installed and
# asserts:
#   1. shell script syntax is valid
#   2. apply.sh bootstraps the machine (tools, omz, plugins, TPM, links)
#   3. every package file is symlinked into HOME
#   4. stow does not fold directories (apps must be able to write into
#      ~/.config without touching the repo)
#   5. the expected CLI tools are installed
#   6. oh-my-zsh, the custom plugins and TPM are present
#   7. zsh is the login shell
#   8. a fresh zsh starts cleanly
#
# Usage: tests/smoke.sh [dotfiles-dir]
# HOME must be writable; it will be created when missing.

set -uo pipefail

DOTFILES="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# The smoke test uses the same manifest parser as apply.sh. It intentionally
# does not maintain a second list of expected tools or plugins.
# shellcheck source=/dev/null
source "$DOTFILES/lib/manifest.sh"

PASS=0
FAIL=0

ok() {
  PASS=$((PASS + 1))
  printf '  [OK]   %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf '  [FAIL] %s\n' "$1"
}

check() { # check <description> <command...>
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    ok "$desc"
  else
    fail "$desc"
  fi
}

if [[ ! -d $HOME ]]; then
  mkdir -p "$HOME"
fi

echo "== 1. Syntax checks =="
check "bash: apply.sh" bash -n "$DOTFILES/apply.sh"
check "bash: lib.sh" bash -n "$DOTFILES/lib.sh"

echo "== 2. apply.sh bootstraps a fresh machine =="
export HOME
status_before="$(git -C "$DOTFILES" status --porcelain 2>/dev/null)"
apply_out=""
if apply_out="$("$DOTFILES/apply.sh" 2>&1)"; then
  ok "apply.sh completed"
else
  fail "apply.sh completed"
  printf '%s\n' "$apply_out" | tail -15 | sed 's/^/       /'
fi

echo "== 3. Tools installed by apply.sh =="
while IFS=$'\t' read -r command_name _fedora_package _macos_package; do
  check "command available: $command_name" command -v "$command_name"
done < <(manifest_rows "$DOTFILES/manifest/tools.tsv")

echo "== 4. Symlink assertions =="
assert_linked() { # assert_linked <relative-path>
  local target="$HOME/$1"
  if [[ -L "$target" && -e "$target" ]]; then
    ok "linked: $1"
  else
    fail "linked: $1"
  fi
}

while IFS= read -r -d '' src; do
  rel="${src#"$DOTFILES/packages/common/"}"
  assert_linked "$rel"
done < <(find "$DOTFILES/packages/common" -type f -print0)

echo "== 5. No directory folding =="
for dir in .config .config/kitty .config/ghostty .local .local/bin; do
  if [[ -d "$HOME/$dir" && ! -L "$HOME/$dir" ]]; then
    ok "real directory: $dir"
  else
    fail "real directory: $dir"
  fi
done

if touch "$HOME/.config/.smoke-write-test" 2>/dev/null; then
  rm -f "$HOME/.config/.smoke-write-test"
  ok "apps can write to ~/.config without touching the repo"
else
  fail "apps can write to ~/.config without touching the repo"
fi

# apply.sh must not dirty the repo. The before-snapshot is only possible when
# git was already installed (on a truly fresh machine it is not), so skip then.
if [[ -n "$status_before" ]]; then
  status_after="$(git -C "$DOTFILES" status --porcelain 2>/dev/null)"
  if [[ "$status_before" == "$status_after" ]]; then
    ok "apply.sh left no new changes in the repo"
  else
    fail "apply.sh left no new changes in the repo"
  fi
else
  ok "repo-clean check skipped (git not installed before bootstrap)"
fi

echo "== 6. zsh ecosystem =="
check "zsh syntax: .zshrc" zsh -n "$DOTFILES/packages/common/.zshrc"
check "zsh syntax: tmux-sessionizer" \
  zsh -n "$DOTFILES/packages/common/.local/bin/tmux-sessionizer"
check "oh-my-zsh installed" test -d "$HOME/.oh-my-zsh/.git"

while IFS=$'\t' read -r plugin_name _repository; do
  check "plugin installed: $plugin_name" \
    test -d "$HOME/.oh-my-zsh/custom/plugins/$plugin_name"
done < <(manifest_rows "$DOTFILES/manifest/zsh-plugins.tsv")

zsh_path="$(command -v zsh)"
user_shell="$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)"
if [[ "$user_shell" == "$zsh_path" ]]; then
  ok "zsh is the login shell"
else
  fail "zsh is the login shell (got: $user_shell)"
fi

echo "== 7. tmux ecosystem =="
check "TPM installed" test -d "$HOME/.tmux/plugins/tpm/.git"
# Directory names are the repo names, e.g. dracula/tmux clones into "tmux".
while IFS= read -r repository; do
  plugin="${repository##*/}"
  check "tmux plugin installed: $plugin" test -d "$HOME/.tmux/plugins/$plugin"
done < <(awk -F"'" '/^[[:space:]]*set(-window)?[[:space:]]+-g[[:space:]]+@plugin/ {print $2}' \
  "$DOTFILES/packages/common/.tmux.conf")

echo "== 8. Fresh zsh startup =="
startup_out="$(zsh -i -c 'echo SMOKE_STARTUP_OK' 2>&1)"
startup_rc=$?
if [[ $startup_rc -eq 0 ]] && [[ "$startup_out" == *SMOKE_STARTUP_OK* ]]; then
  ok "zsh -i starts cleanly"
else
  fail "zsh -i starts cleanly"
  printf '%s\n' "$startup_out" | head -5 | sed 's/^/       /'
fi

if ! [[ "$startup_out" == *"not installed"* ]]; then
  ok "no missing-tool noise on startup"
else
  fail "no missing-tool noise on startup"
fi

echo
printf 'Result: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
