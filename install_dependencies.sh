#!/usr/bin/env bash

# Dotfiles Dependencies Installation Script
# Installs zsh, tmux, and related tools based on the platform

set -e

# Dry run mode flag
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_dry_run() {
    echo -e "${YELLOW}[DRY RUN]${NC} $1"
}

# Execute command or print in dry run mode
execute() {
    if [[ "$DRY_RUN" == "true" ]]; then
        print_dry_run "Would execute: $*"
    else
        "$@"
    fi
}

# Detect the operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|pop)
                echo "debian"
                ;;
            fedora|rhel|centos)
                echo "fedora"
                ;;
            arch|manjaro)
                echo "arch"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Install packages on macOS using Homebrew
install_macos() {
    print_info "Installing dependencies for macOS..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew not found. Installing Homebrew..."
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Would install Homebrew"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    fi
    
    # Core dependencies
    print_info "Installing core packages..."
    execute brew install zsh tmux git curl
    
    # Additional tools mentioned in dotfiles
    print_info "Installing additional tools..."
    execute brew install neovim kitty exa fzf bat yt-dlp lazygit ffmpeg
    
    # Zsh plugins
    print_info "Installing Zsh plugins..."
    execute brew install zsh-autosuggestions zsh-syntax-highlighting zsh-fast-syntax-highlighting
    
    # Optional: Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Installing Oh My Zsh..."
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Would install Oh My Zsh"
        else
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
    else
        print_success "Oh My Zsh already installed"
    fi
    
    # Optional: Install TPM (Tmux Plugin Manager)
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        print_info "Installing Tmux Plugin Manager..."
        execute git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        print_success "TPM already installed"
    fi
    
    # Optional: Install shellfirm
    if ! command -v shellfirm &> /dev/null; then
        print_info "Installing shellfirm..."
        execute brew tap kaplanelad/tap
        execute brew install shellfirm
    fi
    
    print_success "macOS dependencies installed successfully!"
}

# Install packages on Debian/Ubuntu
install_debian() {
    print_info "Installing dependencies for Debian/Ubuntu..."
    
    print_info "Updating package list..."
    execute sudo apt-get update
    
    # Core dependencies
    print_info "Installing core packages..."
    execute sudo apt-get install -y zsh tmux git curl build-essential
    
    # Additional tools
    print_info "Installing additional tools..."
    execute sudo apt-get install -y neovim xclip fzf bat ffmpeg
    
    # Install exa (might need snap or cargo)
    if ! command -v exa &> /dev/null; then
        print_info "Installing exa..."
        if command -v cargo &> /dev/null; then
            execute cargo install exa
        elif command -v snap &> /dev/null; then
            execute sudo snap install exa --classic
        else
            print_warning "Could not install exa. Install Rust/cargo or snapd manually."
        fi
    fi
    
    # Install kitty
    if ! command -v kitty &> /dev/null; then
        print_info "Installing Kitty terminal..."
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Would install Kitty terminal"
        else
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
        fi
    fi
    
    # Install yt-dlp
    if ! command -v yt-dlp &> /dev/null; then
        print_info "Installing yt-dlp..."
        execute sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
        execute sudo chmod a+rx /usr/local/bin/yt-dlp
    fi
    
    # Install lazygit
    if ! command -v lazygit &> /dev/null; then
        print_info "Installing lazygit..."
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Would install lazygit"
        else
            LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
            tar xf lazygit.tar.gz lazygit
            sudo install lazygit /usr/local/bin
            rm lazygit lazygit.tar.gz
        fi
    fi
    
    # Zsh plugins
    print_info "Installing Zsh plugins..."
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
        execute git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
        execute git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting" ]]; then
        execute git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
    fi
    
    # Optional: Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Installing Oh My Zsh..."
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Would install Oh My Zsh"
        else
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
    else
        print_success "Oh My Zsh already installed"
    fi
    
    # Optional: Install TPM
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        print_info "Installing Tmux Plugin Manager..."
        execute git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        print_success "TPM already installed"
    fi
    
    print_success "Debian/Ubuntu dependencies installed successfully!"
}

# Install packages on Fedora/RHEL
install_fedora() {
    print_info "Installing dependencies for Fedora/RHEL..."
    
    # Core dependencies
    print_info "Installing core packages..."
    execute sudo dnf install -y zsh tmux git curl gcc make
    
    # Additional tools
    print_info "Installing additional tools..."
    execute sudo dnf install -y neovim xclip fzf bat ffmpeg
    
    # Install exa
    if ! command -v exa &> /dev/null; then
        print_info "Installing exa..."
        if command -v cargo &> /dev/null; then
            execute cargo install exa
        else
            print_warning "Could not install exa. Install Rust/cargo manually."
        fi
    fi
    
    # Install kitty
    if ! command -v kitty &> /dev/null; then
        print_info "Installing Kitty terminal..."
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Would install Kitty terminal"
        else
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
        fi
    fi
    
    # Install yt-dlp
    if ! command -v yt-dlp &> /dev/null; then
        print_info "Installing yt-dlp..."
        execute sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
        execute sudo chmod a+rx /usr/local/bin/yt-dlp
    fi
    
    # Install lazygit
    if ! command -v lazygit &> /dev/null; then
        print_info "Installing lazygit..."
        execute sudo dnf copr enable atim/lazygit -y
        execute sudo dnf install lazygit -y
    fi
    
    # Zsh plugins
    print_info "Installing Zsh plugins..."
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
        execute git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
        execute git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting" ]]; then
        execute git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
    fi
    
    # Optional: Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Installing Oh My Zsh..."
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Would install Oh My Zsh"
        else
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
    else
        print_success "Oh My Zsh already installed"
    fi
    
    # Optional: Install TPM
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        print_info "Installing Tmux Plugin Manager..."
        execute git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        print_success "TPM already installed"
    fi
    
    print_success "Fedora/RHEL dependencies installed successfully!"
}

# Install packages on Arch Linux
install_arch() {
    print_info "Installing dependencies for Arch Linux..."
    
    print_info "Updating package database..."
    execute sudo pacman -Sy
    
    # Core dependencies
    print_info "Installing core packages..."
    execute sudo pacman -S --noconfirm zsh tmux git curl base-devel
    
    # Additional tools
    print_info "Installing additional tools..."
    execute sudo pacman -S --noconfirm neovim xclip fzf bat ffmpeg exa lazygit
    
    # Install kitty
    if ! command -v kitty &> /dev/null; then
        print_info "Installing Kitty terminal..."
        execute sudo pacman -S --noconfirm kitty
    fi
    
    # Install yt-dlp
    if ! command -v yt-dlp &> /dev/null; then
        print_info "Installing yt-dlp..."
        execute sudo pacman -S --noconfirm yt-dlp
    fi
    
    # Zsh plugins
    print_info "Installing Zsh plugins..."
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
        execute git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
        execute git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting" ]]; then
        execute git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
    fi
    
    # Optional: Install Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Installing Oh My Zsh..."
        if [[ "$DRY_RUN" == "true" ]]; then
            print_dry_run "Would install Oh My Zsh"
        else
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
    else
        print_success "Oh My Zsh already installed"
    fi
    
    # Optional: Install TPM
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        print_info "Installing Tmux Plugin Manager..."
        execute git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        print_success "TPM already installed"
    fi
    
    print_success "Arch Linux dependencies installed successfully!"
}

# Print usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run    Show what would be installed without actually installing"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Example:"
    echo "  $0               # Install dependencies"
    echo "  $0 --dry-run     # Show what would be installed"
    exit 0
}

# Main installation logic
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    print_info "Dotfiles Dependencies Installation Script"
    print_info "=========================================="
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "DRY RUN MODE - No actual changes will be made"
    fi
    echo ""
    
    OS=$(detect_os)
    print_info "Detected OS: $OS"
    echo ""
    
    case "$OS" in
        macos)
            install_macos
            ;;
        debian)
            install_debian
            ;;
        fedora)
            install_fedora
            ;;
        arch)
            install_arch
            ;;
        *)
            print_error "Unsupported operating system: $OS"
            print_error "Please install dependencies manually."
            exit 1
            ;;
    esac
    
    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        print_success "=========================================="
        print_success "Dry run completed!"
        print_success "=========================================="
        echo ""
        print_info "To actually install these dependencies, run without --dry-run flag:"
        echo "  ./install_dependencies.sh"
    else
        print_success "=========================================="
        print_success "All dependencies installed successfully!"
        print_success "=========================================="
        echo ""
        print_info "Next steps:"
        echo "  1. Set zsh as your default shell: chsh -s \$(which zsh)"
        echo "  2. Reload your shell or restart your terminal"
        echo "  3. In tmux, press Ctrl+y I (capital I) to install tmux plugins"
        echo "  4. Run 'source ~/.zshrc' to reload your zsh configuration"
    fi
    echo ""
}

# Run the main function
main "$@"
