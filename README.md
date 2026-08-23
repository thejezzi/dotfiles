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

`apply.sh` is the orchestration layer. It reads the data files in `manifest/`
and passes their values to the reusable mechanisms in `lib/`:

- `manifest/tools.tsv` maps commands to Fedora and macOS package names.
- `manifest/zsh-plugins.tsv` lists plugin names and repository URLs.
- `manifest/repos.tsv` contains bootstrap repository and installer URLs.

The library modules contain no concrete tool or plugin lists. `lib/pkg.sh` knows
how to use `dnf` or Homebrew, `lib/vcs.sh` knows how to clone or update a
repository without overwriting local changes, and `lib/stow.sh` manages the
links. `lib/bin.sh` keeps the reusable `install_bin`, `ensure_in_path` (plus the
`ensure_path` compatibility alias) and `mise_use` utilities. `install_bin` takes
its download URL as an argument; `mise_use` takes its version and installer URL,
so these helpers contain no provider-specific bootstrap data.

`apply_dotfiles()` stows `common` into `$HOME`. Before stowing,
`migrate_stow_links()` walks the package and cleans up stale symlinks in `$HOME`
that would otherwise make stow choke. If a real (non-symlink) file is in the
way, it warns and leaves it alone instead of clobbering anything.

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
