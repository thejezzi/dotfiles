# Dotfiles

My personal dotfiles for Fedora and macOS. Managed with
[GNU Stow](https://www.gnu.org/software/stow/), installed by a single bash script.

## Setup

```sh
./apply.sh
```

That's it. The script installs `stow`, `fzf` and `ripgrep` if they're missing
(`brew` on macOS, `dnf` on Fedora) and then links everything into `$HOME`.

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

`apply_dotfiles()` stows `common` into `$HOME`. Before stowing,
`migrate_stow_links()` walks the package and cleans up stale symlinks in `$HOME`
that would otherwise make stow choke. If a real (non-symlink) file is in the
way, it warns and leaves it alone instead of clobbering anything.

The rest of `lib.sh` is a grab bag of helpers I reuse elsewhere: colored log
functions, `system_install` for installing packages with whatever the native
package manager is, `install_bin` for fetching single binaries from a URL into
`~/.local/bin`, OS detection (`is_macos`, `is_fedora`), and a small `ask` prompt
for yes/no questions.

There's a commented-out bats test in `lib.bats` I keep meaning to get back to.
