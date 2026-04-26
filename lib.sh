say_hello() {
  echo "hi"
}

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

# install tries to find the systems package manager and than attempts to install everything
# necesarry with it.
system_install() {
  local -a pm=()
  local -a missing=()
  if is_macos; then
    ensure_brew
    pm=(brew install)
  elif is_fedora; then
    pm=(sudo dnf install)
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

apply_dotfiles() {
  WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  migrate_stow_links common

  log_info "Applying common dotfiles with stow"
  stow --dir="${WORKDIR}/packages" --target="$HOME" --restow --override='^.*' common

  if is_macos && [[ -d "${WORKDIR}/packages/macos" ]]; then
    migrate_stow_links macos "${WORKDIR}/packages"
    log_info "Applying macOS overrides with stow"
    stow --dir="${WORKDIR}/packages" --target="$HOME" --restow --override='^\.config/opencode/opencode\.json$' macos
  fi
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
