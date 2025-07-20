# Personal Dotfiles

This repository houses my personal dotfiles, designed to create a highly customized and efficient
development environment on Linux/Unix-like systems. It includes configurations for my shell,
terminal emulator, terminal multiplexer, and more, aiming to optimize daily workflows.

## Features

- **Zsh Configuration:** Powered by Oh My Zsh with a curated set of plugins and custom
  aliases/functions for enhanced command-line productivity.
- **Tmux Setup:** A robust tmux configuration for seamless terminal multiplexing, including custom
  keybindings and a modern theme.
- **Kitty Terminal:** Configuration for the fast and feature-rich Kitty terminal emulator, with
  optimized font settings and visual tweaks.
- **Neovim (Submodule):** My personal Neovim configuration, managed as a separate submodule for a
  tailored IDE-like experience in the terminal.
- **Environment Management:** Streamlined environment variable setup for various programming
  languages and tools (Go, Node.js via NVM, Deno, Bun).
- **Utility Aliases & Functions:** A collection of handy aliases and shell functions for common
  tasks, improving efficiency.

## Installation & Setup

To set up these dotfiles, follow these steps:

1. **Clone the repository:**

   ```bash
   git clone --recurse-submodules <repository_url> ~/.dotfiles
   ```

   (Replace `<repository_url>` with the actual URL of this Git repository).
   The `--recurse-submodules` flag is crucial to also clone the Neovim configuration.

2. **Backup Existing Dotfiles (Optional but Recommended):**
   Before symlinking, it's a good idea to back up your current dotfiles:

   ```bash
   mkdir -p ~/.dotfiles_backup
   mv ~/.zshrc ~/.dotfiles_backup/zshrc_$(date +%F_%H-%M-%S) 2>/dev/null
   mv ~/.tmux.conf ~/.dotfiles_backup/tmux.conf_$(date +%F_%H-%M-%S) 2>/dev/null
   mv ~/.config/kitty/kitty.conf ~/.dotfiles_backup/kitty.conf_$(date +%F_%H-%M-%S) 2>/dev/null
   # ... add other files as needed
   ```

3. **Create Symlinks:**
   Create symbolic links from the cloned repository to your home directory:

   ```bash
   ln -s ~/.dotfiles/.zshrc ~/.zshrc
   ln -s ~/.dotfiles/.tmux.conf ~/.tmux.conf
   mkdir -p ~/.config/kitty
   ln -s ~/.dotfiles/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf
   # The Neovim config is a submodule at ~/.dotfiles/.config/nvim
   # It should already be in place due to --recurse-submodules
   ```

4. **Install Dependencies:**

   - **Oh My Zsh:** Follow the instructions on the [Oh My Zsh GitHub page](https://ohmyz.sh/).
   - **Tmux Plugin Manager (TPM):**

     ```bash
     git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
     ```

     Then, inside tmux, press `<prefix>` + `I` (capital i) to install plugins. (Your prefix is `Ctrl+y`).

   - **Zsh Plugins:** Ensure `zsh-autosuggestions`, `zsh-syntax-highlighting`,
     `fast-syntax-highlighting`, and `shellfirm` are installed. You might need to install them
     manually or verify your Oh My Zsh setup handles them.
   - **Other Tools:** Install `nvim` (Neovim), `kitty`, `exa`, `xclip`, `fzf`, `bat`, `yt-dlp`,
     `lazygit`, `curl` (for cheat.sh/ollama functions), `ffmpeg`, and `rpm` if you want to utilize all
     aliases and functions.
   - **Language-specific tools:** Install `goenv`, `nvm`, `deno`, `bun` for respective language
     support.

5. **Reload Configurations:**
   - **Zsh:** Restart your terminal or run `source ~/.zshrc`.
   - **Tmux:** Inside tmux, press `Ctrl+y r` (your prefix then `r`).
   - **Kitty:** Inside Kitty, press `Ctrl+Shift+f5` or run `kitty @ --to=auto reload-config`.

## Key Components & Configuration Highlights

### Zsh (`.zshrc`)

- **Oh My Zsh:** Used for framework and plugin management.
- **Plugins:** `git`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fast-syntax-highlighting`,
  `shellfirm`.
- **Environment Variables:** Configured for Go, NVM, Deno, and Bun for development.
- **Aliases:**
  - `c`: `clear`
  - `open`, `explorer`: `xdg-open`
  - `yy`, `y`, `yq`, `yv`, `yl`, `yql`, `yvl`: Aliases for `yt-dlp` for various video/audio download
    scenarios.
  - `zshconfig`, `ohmyzsh`, `nvimconfig`, `gfvim`, `nvimlab`: Neovim-related aliases for opening
    configs and special Neovim instances.
  - `ssh`: `kitty +kitten ssh` (for enhanced SSH in Kitty).
  - `le`, `lee`: `exa` aliases for better `ls` output with Git info and icons.
  - `setclip`, `getclip`: `xclip` aliases for clipboard interaction.
  - `cddd`: `fzf` and `bat` integration for fuzzy-finding files and opening them in Neovim with
    preview.
  - `lg`: `lazygit`
- **Functions:**
  - `cht()`: Quick access to `cheat.sh` (e.g., `cht python list`).
  - `cht_advanced()`: Interactive `cheat.sh` query (bound to `Ctrl+e`).
  - `ol()`: Run `ollama` with a prompt.
  - `video2gif()`: Convert videos to optimized GIFs using `ffmpeg`.
  - `list_rpm()`: List RPM GPG keys.

### Tmux (`.tmux.conf`)

- **Prefix:** `Ctrl+y` (instead of default `Ctrl+b`).
- **Mouse Support:** Enabled (`set -g mouse on`).
- **Vi Copy Mode:** Enabled with `v` for selection and `y` for copying to system clipboard via
  `xclip`.
- **Pane Navigation:**
  - Split panes: `_` (vertical), `-` (horizontal).
  - Switch panes: `H`, `J`, `K`, `L` (for left, down, up, right).
  - Resize panes: Repeatable `h`, `j`, `k`, `l` for fine-grained resizing.
  - Swap panes: `Ctrl+j`, `Ctrl+k`.
  - Toggle pane zoom: `m`.
  - Move pane to new window: `!` (break pane).
  - Choose window interactively: `w`.
- **Pane Joining/Pushing:** `p` (pull pane), `P` (push pane) for inter-window/session pane
  management.
- **Scratchpad:** `e` to create a popup scratchpad window.
- **Plugins (managed by TPM):**
  - `christoomey/vim-tmux-navigator`: Seamless navigation between Vim/Neovim and tmux panes.
  - `dracula/tmux`: Custom Dracula theme with detailed status line (RAM, Git, Weather).
  - `ofirgall/tmux-window-name`: Dynamic window names based on running processes.
  - `tmux-plugins/tmux-resurrect`: Persists tmux sessions and pane contents across system reboots.

### Kitty (`.config/kitty/kitty.conf`)

- **Font:** `FiraCode Nerd Font` at size `11.0` with `cell_height 100%`.
- **Undercurls:** `thin-sparse` style enabled.
- **Other Potential Customizations (commented out in config but available):** Cursor shape,
  scrollback settings, mouse actions (e.g., copy on select), window padding/borders, tab bar styling,
  background opacity/blur, and a wide array of keyboard shortcuts for navigation, hints, and more.

### Neovim (`.config/nvim/`)

This directory is managed as a Git submodule. For details on its configuration and usage, please
refer to the `README.md` file within the `.config/nvim` directory.

## Usage

- **Shell (Zsh):** Just open your terminal! Aliases and functions are immediately available.
- **Tmux:** Start a tmux session by typing `tmux`. Use `Ctrl+y` as your prefix for all tmux
  commands.
- **Kitty:** Your `kitty.conf` settings will apply automatically when Kitty starts. Explore the
  keybindings (many are `Ctrl+Shift+<key>`) for features like clipboard, scrolling, and window
  management.
