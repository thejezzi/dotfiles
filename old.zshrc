ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
ENABLE_CORRECTION="false"

BULLETTRAIN_CONTEXT_FG="white"
BULLETTRAIN_TIME_BG="#2596be"
BULLETTRAIN_TIME_FG="white"


# kitty ssh fix
if command -v kitty &> /dev/null; then
  [ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fast-syntax-highlighting
  # zsh-autocomplete
  shellfirm
)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="nvim ~/.zshrc"
alias ohmyzsh="nvim ~/.oh-my-zsh"
alias nvimconfig="cd ~/.config/nvim && nvim"

# source ~/.znap/zsh-snap/znap.zsh
# source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"
export GOLANG_CI_DIR="$HOME/go/bin/golangci-lint"
# export PATH="/usr/local/go/bin:$PATH"
# export PATH="$HOME/go/bin:$PATH"

export DENO_INSTALL="/home/flo/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# export path to .bin directory for custom executables
export PATH="$HOME/.bin:$PATH"
export PATH="/usr/bin:$PATH"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# Useful commands

if command -v fzf &> /dev/null && command -v bat &> /dev/null; then
  alias cddd="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"
fi
if command -v exa &> /dev/null; then
  alias le='exa -l --git --icons --group-directories-first'
  alias lee='exa -1la --git --icons --group-directories-first'
fi

# alias that clears on key c
alias c='clear'


# Clipboard aliases to easily copy and paste, if xclip is available
if command -v xclip &> /dev/null; then
  alias setclip="xclip -selection c"
  alias getclip="xclip -selection c -o"
fi

alias explorer='xdg-open'

if command -v curl &> /dev/null; then
  cht() {
    # curl "https://cht.sh/$1/$(echo $2 | tr ' ' '+')"
    curl -s cheat.sh/$*
  }

  cht_advanced() {
    # curl "https://cht.sh/$1/$(echo $2 | tr ' ' '+')"
    # curl -s cht.sh/:list
    read "?Enter language: " lang
    read "?Enter query: " query
    curl -s cheat.sh/$lang/$query | less
  }

  # bind ^y to call cht_advanced
  bindkey -s '^e' 'cht_advanced\n'
fi

export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

# bun completions
[ -s "/home/flo/.bun/_bun" ] && source "/home/flo/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias yy="yt-dlp"

# If yt-dlp is installed
if command -v yt-dlp &> /dev/null
then
  alias y="yt-dlp"
  alias yq="yt-dlp -x --audio-format mp3"
  alias yv="yt-dlp -f bestvideo+bestaudio"
  alias yl="yt-dlp -f bestvideo+bestaudio --merge-output-format mkv"
  alias yql="yt-dlp -x --audio-format mp3 -f bestvideo+bestaudio"
  alias yvl="yt-dlp -f bestvideo+bestaudio --merge-output-format mkv"
fi

alias open="xdg-open"


if command -v ollama &> /dev/null; then
  ol() {
    ollama run llama3 $1
  }
fi
if [ -f "/home/flo/.deno/env" ]; then
  . "/home/flo/.deno/env"
fi


if command -v ffmpeg &> /dev/null; then
  # Convert video to gif file.
  # Usage: video2gif video_file (scale) (fps)
  video2gif() {
    ffmpeg -y -i "${1}" -vf fps=${3:-10},scale=${2:-320}:-1:flags=lanczos,palettegen "${1}.png"
    ffmpeg -i "${1}" -i "${1}.png" -filter_complex "fps=${3:-10},scale=${2:-320}:-1:flags=lanczos[x];[x][1:v]paletteuse" "${1}".gif
    rm "${1}.png"
  }
fi


if command -v rpm &> /dev/null; then
  list_rpm() {
    rpm -q --qf "%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n" gpg-pubkey | sort -k 2
  }
fi

if command -v nvim &> /dev/null; then
  alias gfvim="GOARCH=wasm GOOS=js nvim"
  alias nvimlab="NVIM_APPNAME=nvimlab nvim"
fi
