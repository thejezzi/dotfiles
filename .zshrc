# ==============================================================================
# Zsh & Oh My Zsh Configuration
# ==============================================================================

# --- Oh My Zsh ---
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# --- Plugins ---
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fast-syntax-highlighting
  shellfirm
)

# --- Behavior ---
ENABLE_CORRECTION="false"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

# --- Editor ---
# Set preferred editor for local and remote sessions
export EDITOR='nvim'

# ==============================================================================
# Environment Variables
# ==============================================================================

# --- Go ---
export GOENV_ROOT="$HOME/.goenv"
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export GOLANG_CI_DIR="$HOME/go/bin/golangci-lint"

# --- Node Version Manager (NVM) ---
export NVM_DIR="$HOME/.config/nvm"

# --- Deno ---
export DENO_INSTALL="/home/flo/.deno"

# --- Bun ---
export BUN_INSTALL="$HOME/.bun"

# --- PATH ---
# The order of path elements is important. Paths are searched from left to right.
export PATH="$GOENV_ROOT/bin:$PATH"
export PATH="$GOROOT/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"
export PATH="$DENO_INSTALL/bin:$PATH"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="/usr/bin:$PATH"

# ==============================================================================
# Aliases
# ==============================================================================

# --- General ---
alias c='clear'
alias open="xdg-open"
alias explorer='xdg-open'
alias yy="yt-dlp"

# --- Neovim ---
if command -v nvim &> /dev/null; then
  alias zshconfig="nvim ~/.zshrc"
  alias ohmyzsh="nvim ~/.oh-my-zsh"
  alias nvimconfig="cd ~/.config/nvim && nvim"
  alias gfvim="GOARCH=wasm GOOS=js nvim"
  alias nvimlab="NVIM_APPNAME=nvimlab nvim"
  # Opens up my neovim config with the ChatFullScreen command with runs CodeCompanion, disables the
  # system prompt and executes the only vim command which runs the chat buffer as the only buffer
  # allowing a chatgpt like experience in the terminal without the need to install a dubious llm cli
  # interface.
  alias chat="nvim -c ChatFullScreen"
fi

# --- Kitty ---
if command -v kitty &> /dev/null; then
  [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
fi

# --- Exa ---
if command -v exa &> /dev/null; then
  alias le='exa -l --git --icons --group-directories-first'
  alias lee='exa -1la --git --icons --group-directories-first'
fi

# --- Clipboard (xclip) ---
if command -v xclip &> /dev/null; then
  alias setclip="xclip -selection c"
  alias getclip="xclip -selection c -o"
fi

# --- fzf & bat ---
if command -v fzf &> /dev/null && command -v bat &> /dev/null; then
  alias cddd="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"
fi

# --- yt-dlp ---
if command -v yt-dlp &> /dev/null; then
  alias y="yt-dlp"
  alias yq="yt-dlp -x --audio-format mp3"
  alias yv="yt-dlp -f bestvideo+bestaudio"
  alias yl="yt-dlp -f bestvideo+bestaudio --merge-output-format mkv"
  alias yql="yt-dlp -x --audio-format mp3 -f bestvideo+bestaudio"
  alias yvl="yt-dlp -f bestvideo+bestaudio --merge-output-format mkv"
fi

if command -v lazygit &> /dev/null; then
  alias lg=lazygit
fi

# ==============================================================================
# Functions
# ==============================================================================

# --- Cheat.sh ---
if command -v curl &> /dev/null; then
  cht() {
    curl -s "cheat.sh/$1/$(echo "$2" | tr ' ' '+')"
  }

  cht_advanced() {
    read "?Enter language: " lang
    read "?Enter query: " query
    curl -s "cheat.sh/$lang/$query" | less
  }

  bindkey -s '^e' 'cht_advanced\n'
fi

# --- Ollama ---
if command -v ollama &> /dev/null; then
  ol() {
    ollama run llama3 "$1"
  }
fi

# --- FFmpeg ---
if command -v ffmpeg &> /dev/null; then
  video2gif() {
    ffmpeg -y -i "$1" -vf "fps=${3:-10},scale=${2:-320}:-1:flags=lanczos,palettegen" "$1.png"
    ffmpeg -i "$1" -i "$1.png" -filter_complex "[0:v]fps=${3:-10},scale=${2:-320}:-1:flags=lanczos[x];[x][1:v]paletteuse" "$1.gif"
    rm "$1.png"
  }
fi

# --- RPM ---
if command -v rpm &> /dev/null; then
  list_rpm() {
    rpm -q --qf "%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n" gpg-pubkey | sort -k 2
  }
fi

# ==============================================================================
# Initializations
# ==============================================================================

# --- Oh My Zsh ---
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# --- Zoxide ---
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# --- Starship ---
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# --- Go ---
if command -v goenv &> /dev/null; then
  eval "$(goenv init -)"
fi

# --- NVM ---
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
  . "$NVM_DIR/bash_completion"
fi

# --- Bun ---
if [ -s "$HOME/.bun/_bun" ]; then
  source "$HOME/.bun/_bun"
fi

# --- Deno ---
if [ -f "$HOME/.deno/env" ]; then
  . "$HOME/.deno/env"
fi

# --- Envman ---
if [ -s "$HOME/.config/envman/load.sh" ]; then
  source "$HOME/.config/envman/load.sh"
fi
