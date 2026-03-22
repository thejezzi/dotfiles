# 🚀 Ultimate Dotfiles & Dev Environment

Welcome to my personal dotfiles! This repository holds a heavily optimized, cross-platform (macOS & Linux) configuration for **Zsh**, **Tmux**, **Neovim**, and **Kitty**. 

This document serves as the ultimate tutorial and reference guide to everything this setup can do.

---

## 🛠️ 1. Installation & Bootstrap

To get started on a fresh machine:

```bash
git clone https://github.com/flo/dotfiles.git ~/dotfiles
cd ~/dotfiles
./sync.sh
```

**Post-Install Steps:**
1. Open Tmux by typing `tmux`.
2. Press `Ctrl + z` followed by `Shift + i` (`<prefix> + I`) to fetch and install all Tmux plugins via TPM.
3. Restart your terminal.

---

## 💻 2. Tmux: The Terminal Multiplexer

Tmux is the heart of this workflow. It is heavily customized for speed, ergonomic window management, and seamless Neovim integration.

### 🔑 The Basics
- **Prefix Key:** Rebound from `Ctrl+b` to **`Ctrl+z`** (`<prefix>`).

### 🪟 Pane & Window Management
Forget complex commands. Splitting and moving around is mapped to be logical and fast:

| Action | Shortcut (`<prefix>` + ...) | Description |
| :--- | :--- | :--- |
| **Split Horizontal** | `-` | Splits the current pane left/right (German keyboard friendly) |
| **Split Vertical** | `_` | Splits the current pane top/bottom (German keyboard friendly) |
| **Navigate Panes** | `H`, `J`, `K`, `L` | Move Left, Down, Up, Right (capital letters) |
| **Resize Panes** | `h`, `j`, `k`, `l` | Resize by 5 cells (Hold/Repeatable) |
| **Swap Panes** | `Ctrl + j` / `Ctrl + k` | Swap the current pane with the one below/above |
| **Zoom Pane** | `m` | Maximize current pane (Toggle) |
| **Rotate Windows** | `Ctrl + h` / `Ctrl + l`| Rotate all panes in the window |
| **Break Pane** | `!` | Move the current pane into its own new window |

### 🧠 Smart Features & Workflows

#### 1. SessionX (Fuzzy Session Manager)
- **Shortcut:** `<prefix> + o`
- **What it does:** Opens a beautiful, floating `fzf` popup. It allows you to search, preview, and instantly jump to any open tmux session, window, or even zoxide directories.

#### 2. Extrakto (No-Mouse Copying)
- **Shortcut:** `<prefix> + Tab`
- **What it does:** Scans the current screen for text, URLs, IPs, and file paths. Opens an `fzf` menu where you can fuzzy-find the string and copy it to your clipboard or insert it into the prompt. Zero mouse interaction required.

#### 3. Pane Joining (Teleport Panes)
- **Pull a Pane:** `<prefix> + p` -> Prompts for a source pane (e.g., `2.1`) and pulls it into your current window.
- **Push a Pane:** `<prefix> + P` -> Prompts for a target window (e.g., `2`) and sends your current pane there.

#### 4. Instant Scratchpad
- **Shortcut:** `<prefix> + e`
- **What it does:** Opens a quick floating terminal popup (named "scratch"). Perfect for running a quick command without messing up your pane layout. Press `Ctrl+d` to close it.

#### 5. Opencode & Sessionizer
- **Opencode Popup:** `<prefix> + Ctrl+o` -> Opens the `opencode` CLI agent in a floating popup within the exact same directory.
- **Sessionizer:** `<prefix> + Ctrl+f` -> Triggers `tmux-sessionizer` to instantly spin up or jump to project environments.

#### 6. Continuous Saving (Never Lose Work)
- **Tmux Resurrect & Continuum:** Your Tmux environment is saved automatically in the background every 15 minutes. If you restart your PC, your sessions, windows, and pane contents will be exactly where you left them.

---

## 🐚 3. Shell Superpowers (Zsh)

The Zsh configuration is built for extreme speed. Heavy plugins (like NVM and GPG) are lazy-loaded asynchronously (`zsh-defer`), ensuring your prompt appears instantly.

### 🪄 Autocompletion & Quality of Life
- **FZF-Tab:** Press `Tab` and your normal autocomplete is replaced by a highly interactive, fuzzy-searchable `fzf` menu.
- **Sudo Magic:** Typed a long command but forgot `sudo`? Just press `ESC` twice! It prepends `sudo` to your current line automatically.
- **Extract Everything:** Forget `tar -xvf` or `unzip`. Just type `extract <filename>` and it handles any archive type.
- **Fish-like Suggestions:** `zsh-autosuggestions` predicts what you want to type based on your history. Press `Ctrl + L` to accept the suggestion.

### 📁 File Exploration & Navigation
- **`z` (Zoxide):** A smarter `cd`. Just type `z proj` to jump to `/path/to/my-awesome-project`.
- **`le` & `lee` (Eza):** Replaces `ls` with `eza`. It features beautiful icons, color-coding, and groups directories first. (e.g., `le` for a clean list, `lee` for all hidden files).
- **`cddd`:** Type `cddd`. It opens an `fzf` file finder with a live, syntax-highlighted preview of the files using `bat`. Select a file to open it instantly in Neovim.

### 🛠️ Awesome Aliases & Functions
| Command | What it does |
| :--- | :--- |
| **`chat`** | Opens Neovim directly in full-screen AI chat mode using CodeCompanion. It feels like a dedicated ChatGPT terminal CLI. |
| **`Ctrl + E`** | Opens an interactive prompt asking for a language and query, then fetches community cheat sheets directly from `cheat.sh`. |
| **`video2gif`** | Converts a video file to an optimized GIF using `ffmpeg`. (Usage: `video2gif input.mp4 320 10`) |
| **`setclip` / `getclip`** | Cross-platform clipboard commands. Works seamlessly on macOS (`pbcopy`) and Linux (`xclip`). |
| **`y` / `yq` / `yv`** | `yt-dlp` wrappers. E.g., `yq <url>` downloads and converts a YouTube video to an MP3 instantly. |

---

## 📝 4. Editor & Neovim

Neovim (`nvim`) is the default editor (`$EDITOR`). It is deeply integrated into the ecosystem:
- **Vim-Tmux-Navigator:** You can use `Ctrl + h/j/k/l` to move seamlessly between Neovim splits and Tmux panes without noticing the difference.
- **Zero Escape Delay:** Tmux is configured with `escape-time 0`, meaning pressing `ESC` in Neovim has exactly zero lag.
- **Focus Events:** `focus-events on` tells Neovim when you switch to its pane, automatically triggering file reloads if a file changed externally.
- **Quick Configs:** Use the aliases `zshconfig`, `ohmyzsh`, and `nvimconfig` to instantly jump into editing your configuration files.

---

## 🌐 5. Cross-Platform Harmony
This config was built to "just work", whether you are on an Apple Silicon Mac, an Intel Mac, or a Linux machine:
- Automatically detects OS (`$OSTYPE`) to apply macOS-specific SSH tweaks or Linux fallbacks.
- Intelligently loads the correct Homebrew path (`/opt/homebrew` vs `/usr/local` vs `/home/linuxbrew`).
- Safely loads your Gemini API Key via a backgrounded `gpg` decryption job, keeping it out of your static files and preventing shell lock-ups.

Enjoy your ultimate terminal experience! 🚀
