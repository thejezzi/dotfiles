# Dotfiles

My personal dotfiles for Fedora and macOS. Managed with
[GNU Stow](https://www.gnu.org/software/stow/), installed by a single bash script.

## Setup

```sh
./apply.sh
```

That's it. The script bootstraps a fresh machine end to end:

1. **System packages** — installs everything the setup expects (`zsh`, `stow`,
   `git`, `curl`, `tmux`, `fzf`, `ripgrep`, `fd`, `eza`, `bat`, `zoxide`) with
   the native package manager (`brew` on macOS, `dnf` on Fedora), resolving
   command-to-package name differences per platform.
2. **Dotfiles** — links `packages/common` into `$HOME` via GNU Stow.
3. **Shell ecosystem** — clones/updates oh-my-zsh and the custom plugins used
   in `.zshrc` (zsh-autosuggestions, fast-syntax-highlighting, fzf-tab,
   shellfirm, zsh-defer).
4. **tmux ecosystem** — clones/updates TPM and installs the tmux plugins
   headlessly.
5. **Login shell** — sets zsh as the default shell (via `chsh`, adding it to
   `/etc/shells` first when needed).

Everything is idempotent: rerunning `./apply.sh` updates what is already
there (skipping repos with local modifications) and only installs what is
missing.

## Layout

Config files live under `packages/`:

- `packages/common` — everything that applies on both systems: `.zshrc`,
  `.tmux.conf`, kitty and ghostty configs, opencode, and `tmux-sessionizer`
  (a small fzf-based script in `.local/bin` for jumping between tmux sessions)

Each package mirrors the directory structure of `$HOME`, so
`packages/common/.tmux.conf` becomes `~/.tmux.conf` and so on.
Platform-specific packages (e.g. `packages/macos`) can be added back when a
config actually needs to differ between systems.

## How it works

All the logic sits in `lib.sh`, `apply.sh` is just the entry point.

`install_tools()` checks each expected command and installs the missing ones,
mapping command names to package names per platform (`rg` → `ripgrep`,
`fd` → `fd-find` on Fedora). `ensure_oh_my_zsh()`, `ensure_zsh_plugins()` and
`ensure_tpm()` clone their repos when missing and fast-forward them when clean;
repos with local changes are skipped with a note. `ensure_default_shell()`
switches the login shell to zsh via `chsh`.

`apply_dotfiles()` stows `common` into `$HOME`. Before stowing,
`migrate_stow_links()` walks the package and cleans up stale symlinks in `$HOME`
that would otherwise make stow choke. If a real (non-symlink) file is in the
way, it warns and leaves it alone instead of clobbering anything.

The rest of `lib.sh` is a grab bag of helpers I reuse elsewhere: colored log
functions, `system_install` for installing packages with whatever the native
package manager is, `install_bin` for fetching single binaries from a URL into
`~/.local/bin`, OS detection (`is_macos`, `is_fedora`), and a small `ask` prompt
for yes/no questions.

## Testing

```sh
make test-container
```

Builds a bare `fedora:latest` image (nothing preinstalled) and runs
`tests/smoke.sh` inside it against an empty `$HOME`: `apply.sh` must bootstrap
the machine from zero, then 48 assertions check the installed tools, symlinks,
oh-my-zsh/plugins/TPM, the default shell and a clean zsh startup.
`CONTAINER_RT=docker make test-container` works too.

There's a commented-out bats test in `lib.bats` I keep meaning to get back to.
