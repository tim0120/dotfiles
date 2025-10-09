# ============================================================================
# EARLY INITIALIZATION
# ============================================================================

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Fun startup message
fortune | cowsay -r -W 100 --think

# Powerlevel10k instant prompt (must be near top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
# OH-MY-ZSH CONFIGURATION
# ============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
ENABLE_CORRECTION="true"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Powerlevel10k customization
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

export EDITOR='vim'
export DBUS_SESSION_BUS_ADDRESS="unix:path=$DBUS_LAUNCHD_SESSION_BUS_SOCKET"
export LITELLM_SILENT=True

# Load secrets from .env if available
if [ -f ~/.env ]; then
  source ~/.env
fi

# ============================================================================
# PATH CONFIGURATION
# ============================================================================

# User binaries
export PATH="$HOME/.local/bin:$PATH"

# Development tools
export PATH="$HOME/.codeium/windsurf/bin:$PATH"
export PATH="$PATH:$HOME/.cargo/bin"

# TeX Live
export PATH="/usr/local/texlive/2024/bin/x86_64-darwin:$PATH"

# Nebius CLI (conditional)
if [ -f "$HOME/.nebius/path.zsh.inc" ]; then
  source "$HOME/.nebius/path.zsh.inc"
fi

# ============================================================================
# ALIASES
# ============================================================================

alias downloads="~/Downloads"
alias nv="nvim"
alias nvimrc="nvim ~/.config/nvim/init.vim"
alias nz="nvim ~/.zshrc"
alias sz="source ~/.zshrc"
alias mkdircd='(){ mkdir "$1" && cd "$1"}'

# ============================================================================
# FUNCTIONS
# ============================================================================

# SSH tunnel for Jupyter notebook
function jupyter_ssh(){
    server=$1
    project=$2
    port=$(shuf -i 9310-9329 -n 1)
    ssh -L localhost:$port\:localhost:$port $server -t "zsh --login -i -c '$project && jupyter notebook --port $port --no-browser'"
}

# Auto-ls on directory change
function chpwd() {
  emulate -L zsh
  ls
}

# ============================================================================
# TOOL INITIALIZATION
# ============================================================================

# thefuck command correction
eval $(thefuck --alias)

# Conda (managed by conda init)
__conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# scm_breeze (git shortcuts)
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"

# zoxide (smarter cd)
eval "$(zoxide init zsh)"

# ============================================================================
# SHELL BEHAVIOR
# ============================================================================

# Ghostty: Block cursor
printf '\033[1 q'

function _reset_cursor() {
    printf '\033[1 q'
}
precmd_functions+=(_reset_cursor)

# Emacs mode for line editing
bindkey -e

function zle-line-init {
    printf '\033[1 q'
}
zle -N zle-line-init
