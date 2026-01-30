# ============================================================================
# ZSHRC CONFIGURATION
# ============================================================================

# ============================================================================
# INSTANT PROMPT - Must be at the very top
# ============================================================================

# Reset terminal to normal key encoding mode (prevents Shift+Enter printing [13;2u)
if [[ -t 1 ]]; then
  printf '\e[>4;0m\e[<0u' 2>/dev/null
fi

# Powerlevel10k instant prompt (must be before any console output)
# DISABLED for Starship:
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# ============================================================================
# ZINIT - Plugin Manager
# ============================================================================

# Load Zinit
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ============================================================================
# HOMEBREW - Cached to avoid repeated eval
# ============================================================================

BREW_CACHE="$HOME/.cache/brew-shellenv"
if [[ /opt/homebrew/bin/brew -nt "$BREW_CACHE" ]] || [[ ! -f "$BREW_CACHE" ]]; then
    mkdir -p "$HOME/.cache"
    /opt/homebrew/bin/brew shellenv > "$BREW_CACHE"
fi
source "$BREW_CACHE"

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

export EDITOR='vim'
export DBUS_SESSION_BUS_ADDRESS="unix:path=$DBUS_LAUNCHD_SESSION_BUS_SOCKET"
export LITELLM_SILENT=True

# Load secrets from .env if available
if [ -f ~/.env ]; then
  export $(grep -v '^#' ~/.env | xargs)
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

# Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# ============================================================================
# GIT NUMBERED SHORTCUTS - scmpuff
# ============================================================================

eval "$(scmpuff init -s)"

# ============================================================================
# PLUGINS - Loaded with Zinit Turbo Mode (loads AFTER prompt)
# ============================================================================

# Load Powerlevel10k theme
# DISABLED for Starship:
# zinit ice depth=1
# zinit light romkatv/powerlevel10k

# Load plugins in turbo mode - they load AFTER the prompt appears!
# This means 0ms blocking on startup

# Syntax highlighting and autosuggestions (load 0ms after prompt)
zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

# Git aliases (works with scmpuff numbered files)
alias gpl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gb='git branch'
alias gbd='git branch -d'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gcp='git cherry-pick'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gm='git merge'
alias gf='git fetch'
alias gfa='git fetch --all'
alias gr='git remote -v'

# ============================================================================
# LAZY LOADED TOOLS - Only load when first used
# ============================================================================

# thefuck - lazy load
fuck() {
    unfunction "$0"
    eval $(thefuck --alias)
    fuck "$@"
}

# zoxide - lazy load
z() {
    unfunction "$0"
    eval "$(zoxide init zsh)"
    z "$@"
}

# ============================================================================
# ALIASES
# ============================================================================

alias downloads="~/Downloads"
alias nv="nvim"
alias nvimrc="nvim ~/.config/nvim/init.vim"
alias nz="nvim ~/.zshrc"
alias sz="source ~/.zshrc"
alias mkdircd='(){ mkdir "$1" && cd "$1"}'

# Safe rm - use trash instead of permanent deletion
alias rm='trash'
alias realrm='/bin/rm'

# Basic ls aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

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
# SHELL BEHAVIOR
# ============================================================================

# Load zsh's hook system
autoload -Uz add-zsh-hook

# Command notifications for long-running commands (5+ seconds)
_notify_on_long_command() {
  _cmd_start_time=$EPOCHSECONDS
}

_notify_after_command() {
  local exit_code=$?

  if [[ -n $_cmd_start_time ]]; then
    local duration=$((EPOCHSECONDS - _cmd_start_time))

    if (( duration >= 5 )); then
      local status_icon=$([ $exit_code -eq 0 ] && echo "✓" || echo "✗")
      local cmd_text="$(fc -ln -1 | sed 's/^[[:space:]]*//')"
      if [[ -n "$TMUX" ]]; then
        echo -e "\033Ptmux;\033\033]777;notify;$status_icon (${duration}s);$cmd_text\007\033\\"
      else
        echo -e "\033]777;notify;$status_icon (${duration}s);$cmd_text\007"
      fi
    fi
  fi

  unset _cmd_start_time
}

# Register the hooks
add-zsh-hook preexec _notify_on_long_command
add-zsh-hook precmd _notify_after_command

# Tmux: Add newline before prompt for easier {} navigation in copy mode
if [[ -n "$TMUX" ]]; then
  _tmux_prompt_newline() { echo }
  add-zsh-hook precmd _tmux_prompt_newline
fi

# Ghostty: Block cursor
printf '\033[1 q'

function _reset_cursor() {
    printf '\033[1 q'
}
precmd_functions+=(_reset_cursor)

# Emacs mode for line editing
bindkey -e

# Map Shift+Enter (CSI u sequence) back to a normal newline
bindkey -M emacs '^[[13;2u' accept-line
bindkey -M viins '^[[13;2u' accept-line
bindkey -M emacs '^[[27;2;13~' accept-line
bindkey -M viins '^[[27;2;13~' accept-line

# Claude wrapper: mark pane for tmux and disable ext-keys while Claude runs
claude() {
  local _tmux_pane="$TMUX_PANE"
  if [[ -n "$TMUX" && -n "$_tmux_pane" ]]; then
    tmux set-option -p @is_claude 1 2>/dev/null
  fi

  if [[ -t 1 ]]; then
    printf '\e[>4;0m\e[<0u'
  fi

  command claude "$@"
  local _code=$?

  if [[ -t 1 ]]; then
    printf '\e[>4;1m\e[<1u'
  fi
  if [[ -n "$TMUX" && -n "$_tmux_pane" ]]; then
    tmux set-option -p @is_claude '' 2>/dev/null
  fi
  return $_code
}

function zle-line-init {
    printf '\033[1 q'
}
zle -N zle-line-init

# ============================================================================
# COMPLETIONS
# ============================================================================

# Completion initialization
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qNmh+24) ]]; then
    compinit
else
    compinit -C
fi

# ============================================================================
# TIM'S BOX SCRIPTS - Load if available
# ============================================================================

# Auto-source Tim's box scripts from main pollux repo (works anywhere)
# Always source to ensure functions are defined in new shells
# Pre-set POLLUX_DIR to avoid path detection issues when sourcing from /
if [ -f ~/Developer/workshop_labs/pollux/bash/tim/all.sh ]; then
  export POLLUX_DIR=~/Developer/workshop_labs/pollux
  source ~/Developer/workshop_labs/pollux/bash/tim/all.sh
elif [ -f ~/Developer/workshop_labs/timbox/bash/tim/all.sh ]; then
  export POLLUX_DIR=~/Developer/workshop_labs/timbox
  source ~/Developer/workshop_labs/timbox/bash/tim/all.sh
fi

# ============================================================================
# CUSTOM SHELL TOOLS
# ============================================================================

# Load custom shell tools if available
if [ -f ~/bin/tools/load-tools.sh ]; then
  source ~/bin/tools/load-tools.sh
fi

export NEBIUS_PROFILE=sa-skypilot-uspoc

# ============================================================================
# POWERLEVEL10K CONFIG (disabled for Starship)
# ============================================================================

# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================================================
# STARSHIP PROMPT
# ============================================================================

eval "$(starship init zsh)"

# Transient prompt - collapses old prompts to just ❯
TRANSIENT_PROMPT_TRANSIENT_PROMPT='%F{242}❯%f '
zinit light olets/zsh-transient-prompt

# ============================================================================
# OPTIONAL FUN - Fortune/Cowsay (only 20% of the time)
# ============================================================================

# Show fortune only sometimes
if (( RANDOM % 5 == 0 )); then
    fortune -s 2>/dev/null | cowsay -r -W 100 --think 2>/dev/null || true
fi
