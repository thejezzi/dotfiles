# ANSI color encoding
ANSI_RESET=$'\033[0m'
ANSI_RED=$'\033[31m'
ANSI_GREEN=$'\033[32m'
ANSI_YELLOW=$'\033[33m'
ANSI_BLUE=$'\033[34m'

color() {
  local code="$1"
  local msg="$2"

  printf '%b' "${code}${msg}${ANSI_RESET}"
}

log_info() {
  printf '[%s] %s\n' "$(color "${ANSI_BLUE}" "INFO")" "$*"
}

log_success() {
  printf '[%s] %s\n' "$(color "${ANSI_GREEN}" "OK")" "$*"
}

log_warn() {
  printf '[%s] %s\n' "$(color "${ANSI_YELLOW}" "WARN")" "$*"
}

log_error() {
  printf '[%s] %s\n' "$(color "${ANSI_RED}" "ERROR")" "$*" >&2
}

has_command() {
  local cmd="$1"
  command -v "$cmd" &>/dev/null
}

# Run a command as root: directly when already root, via sudo otherwise.
# (Fresh containers often run as root without sudo installed.)
as_root() {
  if ((EUID == 0)); then
    "$@"
  else
    sudo "$@"
  fi
}

install_bin() {
  local url="$1"
  local name="${2:-${url##*/}}"
  local dir="${3:-$HOME/.local/bin}"
  local out=""

  if [[ -z "$url" ]]; then
    log_error "Usage: install_bin <url> [name] [dir]"
    return 1
  fi

  if [[ -z "$name" ]]; then
    log_error "Could not infer binary name from URL: $url"
    return 1
  fi

  mkdir -p "$dir"
  ensure_in_path "$dir" || true
  out="${dir}/${name}"

  if has_command curl; then
    curl -fsSL "$url" -o "$out"
  elif has_command wget; then
    wget -qO "$out" "$url"
  else
    log_error "curl or wget is required"
    return 1
  fi

  chmod +x "$out"
  log_success "Installed ${name} to ${out}"
}

ensure_in_path() {
  local dir="${1:-$HOME/.local/bin}"

  case ":$PATH:" in
  *":$dir:"*)
    log_info "${dir} is already in PATH"
    return 0
    ;;
  esac

  log_warn "${dir} is not in PATH"
  log_warn "Add this line to your shell config: export PATH=\"${dir}:\$PATH\""
  return 1
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

is_fedora() {
  [[ -f "/etc/os-release" ]] && grep -qi "ID=fedora" /etc/os-release
}

is_pkg_installed() {
  local pkg="$1"
  if is_macos; then
    brew list --versions "$pkg" >/dev/null 2>&1
  elif is_fedora; then
    rpm -q "$pkg" >/dev/null 2>&1
  else
    return 1
  fi
}

ask() {
  local question="$1"
  local answer
  printf "[%s] %s " "$(color "${ANSI_GREEN}" "?")" "$question"
  read -r -p "[y/N] " answer
  case "${answer,,}" in
  y | yes) return 0 ;;
  *) return 1 ;;
  esac
}

ensure_brew() {
  if ! has_command "brew"; then
    log_warn "You need to have brew on your system for this to work"
    if ask "Autoinstall brew?"; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
  fi
}

mise_use() {
  if ! has_command mise; then
    log_warn "Command mise could not be found"
    if ask "Install mise via https://mise.run?"; then
      curl https://mise.run | sh
    fi
    log_success "Mise installed"
  fi

  mise use -g "$1"
}

# Maps a command name to its package name on the current platform.
# Needed because command != package for some tools (rg -> ripgrep, fd -> fd-find).
pkg_name_for() {
  local cmd="$1"
  case "$cmd" in
  rg) echo "ripgrep" ;;
  fd)
    if is_macos; then
      echo "fd"
    else
      echo "fd-find"
    fi
    ;;
  *) echo "$cmd" ;;
  esac
}

# install tries to find the systems package manager and than attempts to install everything
# necesarry with it.
system_install() {
  local -a pm=()
  local -a missing=()
  if is_macos; then
    ensure_brew
    pm=(brew install)
  elif is_fedora; then
    pm=(as_root dnf install -y)
  else
    log_error "OS not supported"
    return 1
  fi

  for pkg in "$@"; do
    if ! is_pkg_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done

  if ((${#missing[@]} == 0)); then
    log_info "Everything up to date."
    return 0
  fi

  log_info "Installing: ${missing[*]}"
  "${pm[@]}" "${missing[@]}"
  log_success "Installed all dependencies."
}

# Commands the dotfiles setup expects to be available on every machine.
TOOL_COMMANDS=(zsh stow git curl tmux fzf rg fd eza bat zoxide)

# Installs every missing tool, resolving command -> package names per platform.
install_tools() {
  local -a missing=()
  local cmd
  for cmd in "${TOOL_COMMANDS[@]}"; do
    if ! has_command "$cmd"; then
      missing+=("$(pkg_name_for "$cmd")")
    fi
  done

  if ((${#missing[@]} == 0)); then
    log_info "All tools already installed."
    return 0
  fi

  system_install "${missing[@]}"
}

current_login_shell() {
  local user
  user="$(id -un)"
  if is_macos; then
    dscl . -read "/Users/${user}" UserShell 2>/dev/null | awk '{print $2}'
  else
    getent passwd "${user}" 2>/dev/null | cut -d: -f7 \
      || awk -F: -v u="${user}" '$1==u {print $7}' /etc/passwd
  fi
}

# Makes zsh the login shell for the current user. Idempotent: does nothing
# when zsh is already the default.
ensure_default_shell() {
  if ! has_command zsh; then
    log_error "zsh is not installed, cannot set it as default shell"
    return 1
  fi

  local zsh_path current_shell user
  zsh_path="$(command -v zsh)"
  current_shell="$(current_login_shell)"
  user="$(id -un)"

  if [[ "$current_shell" == "$zsh_path" ]]; then
    log_info "zsh is already the default shell for ${user}"
    return 0
  fi

  # chsh refuses shells that are not listed in /etc/shells
  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    log_info "Adding ${zsh_path} to /etc/shells"
    echo "$zsh_path" | as_root tee -a /etc/shells >/dev/null
  fi

  log_info "Setting default shell for ${user} to ${zsh_path} (was: ${current_shell})"
  if is_macos; then
    # chsh on macOS prompts for the user's own password
    chsh -s "$zsh_path"
  else
    as_root chsh -s "$zsh_path" "$user"
  fi

  if [[ "$(current_login_shell)" == "$zsh_path" ]]; then
    log_success "Default shell is now zsh (takes effect on next login)"
  else
    log_warn "Could not change default shell automatically"
    return 1
  fi
}

# Pulls a git repo only when its working tree is clean; repos with local
# modifications (e.g. installed/upgraded by their own tooling) are left alone.
update_repo() {
  local dir="$1"
  local label="${2:-$1}"

  if [[ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ]]; then
    log_info "${label}: local changes present, skipping update"
    return 0
  fi

  git -C "$dir" pull --ff-only -q || log_warn "${label}: update failed"
}

# Clones or updates oh-my-zsh. Uses git directly instead of the official
# installer because that one also changes the login shell and execs zsh.
ensure_oh_my_zsh() {
  # Guard against running twice per apply.sh run (called directly and from
  # ensure_zsh_plugins).
  if [[ "${_OMZ_ENSURED:-}" == "1" ]]; then
    return 0
  fi
  _OMZ_ENSURED=1

  local omz_dir="$HOME/.oh-my-zsh"
  if [[ -d "$omz_dir/.git" ]]; then
    log_info "oh-my-zsh already present, updating"
    update_repo "$omz_dir" "oh-my-zsh"
    return 0
  fi

  log_info "Installing oh-my-zsh"
  git clone -q --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$omz_dir"
  log_success "oh-my-zsh installed to ${omz_dir}"
}

# Custom zsh plugins referenced in packages/common/.zshrc.
# Format: <plugin-dir-name> <github-repo>
ZSH_PLUGINS=(
  "zsh-autosuggestions zsh-users/zsh-autosuggestions"
  "fast-syntax-highlighting zdharma-continuum/fast-syntax-highlighting"
  "fzf-tab Aloxaf/fzf-tab"
  "shellfirm kaplanelad/shellfirm"
  "zsh-defer romkatv/zsh-defer"
)

ensure_zsh_plugins() {
  local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
  local entry name repo dest

  ensure_oh_my_zsh
  mkdir -p "$plugins_dir"

  for entry in "${ZSH_PLUGINS[@]}"; do
    name="${entry%% *}"
    repo="${entry##* }"
    dest="${plugins_dir}/${name}"
    if [[ -d "$dest/.git" ]]; then
      update_repo "$dest" "$name"
    elif [[ -d "$dest" ]]; then
      log_warn "${name}: directory exists but is not a git clone, skipping"
    else
      log_info "Installing zsh plugin: ${name}"
      git clone -q --depth 1 "https://github.com/${repo}.git" "$dest" \
        || log_warn "install failed for ${name}"
    fi
  done
  log_success "zsh plugins installed"
}

# Installs TPM and runs its headless plugin installer. Requires ~/.tmux.conf
# to be linked already, because the plugin list is read from it.
ensure_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir/.git" ]]; then
    log_info "TPM already present, updating"
    update_repo "$tpm_dir" "TPM"
  else
    log_info "Installing TPM"
    git clone -q --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  log_info "Installing tmux plugins"
  if "$tpm_dir/bin/install_plugins"; then
    log_success "tmux plugins installed"
  else
    log_warn "tmux plugin install reported errors"
  fi
}

apply_dotfiles() {
  WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  migrate_stow_links common

  log_info "Applying common dotfiles with stow"
  # --no-folding prevents stow from symlinking whole directories (e.g. ~/.config)
  # into the repo. Without it, apps writing into those directories would drop
  # untracked files into the dotfiles checkout on a fresh machine.
  stow --dir="${WORKDIR}/packages" --target="$HOME" --restow --no-folding --override='^.*' common

  # Platform-specific packages (e.g. packages/macos) can be stowed on top here
  # once a config actually needs to differ between systems.
}

migrate_stow_links() {
  # package describes which package of dotfiles should be deployed
  local package="$1"
  # package dir is the actual directory of the package
  local pkg_dir="${WORKDIR}/packages/${package}"
  local src=""
  local rel=""
  local dst=""
  local removed=0

  if [[ ! -d "$pkg_dir" ]]; then
    log_warn "Package directory missing, skipping migration: $pkg_dir"
    return 0
  fi

  while IFS= read -r -d '' src; do
    rel="${src#"$pkg_dir"/}"
    dst="$HOME/$rel"

    if [[ -L "$dst" && ! -e "$dst" ]]; then
      log_info "Removing stale symlink: $dst"
      rm "$dst"
      removed=$((removed + 1))
      continue
    fi

    if [[ -e "$dst" && ! -L "$dst" ]]; then
      log_warn "Existing real file blocks stow: $dst"
    fi
  done < <(find "$pkg_dir" \( -type f -o -type l \) -print0)

  if ((removed > 0)); then
    log_success "Migrated $removed stale symlink(s) for package '$package'"
  fi
}
