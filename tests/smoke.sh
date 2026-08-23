#!/usr/bin/env bash
# smoke.sh — platform-agnostic fresh-machine smoke test for the dotfiles.
#
# Runs against an empty HOME and asserts:
#   1. shell script syntax is valid
#   2. apply.sh completes and links every package file into HOME
#   3. stow does not fold directories (apps must be able to write into
#      ~/.config without touching the repo)
#   4. a fresh zsh starts cleanly without oh-my-zsh, plugins or extra tools
#
# Usage: tests/smoke.sh [dotfiles-dir]
# Expects to run as whatever user owns $HOME; HOME must be empty/writable.

set -uo pipefail

DOTFILES="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

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
check "bash: apply.sh"  bash -n "$DOTFILES/apply.sh"
check "bash: lib.sh"    bash -n "$DOTFILES/lib.sh"
check "zsh: .zshrc"     zsh -n "$DOTFILES/packages/common/.zshrc"
check "zsh: tmux-sessionizer" \
  zsh -n "$DOTFILES/packages/common/.local/bin/tmux-sessionizer"

echo "== 2. apply.sh against fresh HOME =="
export HOME
status_before="$(git -C "$DOTFILES" status --porcelain 2>/dev/null)"
apply_out=""
if apply_out="$("$DOTFILES/apply.sh" 2>&1)"; then
  ok "apply.sh completed"
else
  fail "apply.sh completed"
  printf '%s\n' "$apply_out" | head -5 | sed 's/^/       /'
fi

echo "== 3. Symlink assertions =="
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

echo "== 4. No directory folding =="
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

# apply.sh must not dirty the repo: compare the git status before/after.
status_after="$(git -C "$DOTFILES" status --porcelain 2>/dev/null)"
if [[ "$status_before" == "$status_after" ]]; then
  ok "apply.sh left no new changes in the repo"
else
  fail "apply.sh left no new changes in the repo"
fi

echo "== 5. Fresh zsh startup =="
startup_out="$(zsh -i -c 'echo SMOKE_STARTUP_OK' 2>&1)"
startup_rc=$?
if [[ $startup_rc -eq 0 ]] && [[ "$startup_out" == *SMOKE_STARTUP_OK* ]]; then
  ok "zsh -i starts cleanly without oh-my-zsh/plugins"
else
  fail "zsh -i starts cleanly without oh-my-zsh/plugins"
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
