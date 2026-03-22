# Dotfiles

A modern, fast, and feature-rich configuration repository for my daily workflow across macOS and Linux.

## 🚀 Features

### Core Technologies
- **Shell**: Zsh managed via [Oh My Zsh](https://ohmyz.sh/)
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/)
- **Editor**: [Neovim](https://neovim.io/)

### Shell Experience (Zsh)
- **Lazy Loading**: Utilizes `zsh-defer` to load heavier integrations (like NVM and GPG keys) asynchronously, keeping the Time-To-First-Prompt (TTFP) extremely low.
- **Starship Prompt**: A blazing fast, customizable prompt for any shell.
- **Smart Plugins**:
  - `fzf-tab`: Replaces default autocompletion with a dynamic, interactive fuzzy-finding menu.
  - `zsh-autosuggestions` & `fast-syntax-highlighting`: For real-time feedback and fish-like autocompletions.
  - `sudo`: Press `ESC` twice to prefix your current command with `sudo`.
  - `extract`: Unpack any archive without remembering `tar`, `unzip`, etc. (`extract file.tar.gz`).
  - `copypath` / `copyfile`: Instantly copy paths and files to your clipboard.

### Essential CLI Tools
- **fzf**: Fuzzy finder integrated with `rg` (Ripgrep) as the default engine to search files blazingly fast while respecting `.gitignore`.
- **eza**: Modern, colorful replacement for `ls` (`le` and `lee` aliases).
- **bat**: A `cat` clone with syntax highlighting. Also configured globally as the default `MANPAGER` to read man pages in full color.
- **zoxide**: A smarter `cd` command that learns your habits.
- **mise**: Manage local environments, versions, and tasks effortlessly.

### Neovim Workflow
- Native integration through alias workflows (`zshconfig`, `ohmyzsh`, `nvimconfig`).
- Special aliases like `gfvim` for Go/Wasm environment and `chat` to spin up an instant CodeCompanion AI chat interface seamlessly inside Neovim.
- Dedicated `cddd` alias to search files using `fzf` + `bat` preview and open them directly in Neovim.

### Media & Utils
- **yt-dlp**: Simplified aliases (`yv`, `yq`, `yl`) to download high-quality videos or extract audio directly from the terminal.
- **ffmpeg**: Handy `video2gif` bash function to convert videos to optimized gifs easily.
- **cheat.sh (`cht`)**: Direct terminal access to community-driven cheat sheets (press `Ctrl + E` for advanced interactive mode).

### Cross-Platform Harmony
- Automatic detection of the OS (`OSTYPE` checks for macOS vs. Linux).
- Dynamic adaptation of package managers (Homebrew on macOS vs. Linuxbrew).
- OS-agnostic aliases for clipboard (`pbcopy`/`pbpaste` vs `xclip`) and file explorers (`open` vs `xdg-open`).
- Secure API key fetching (Gemini API via GPG), safely tucked away into background processes.

## 🔄 Installation & Sync
This repository includes a `sync.sh` script to easily bootstrap and synchronize these configurations across different machines.
