# .zshenv - Sourced for ALL zsh shells (interactive and non-interactive)
# This file is loaded before .zshrc and for every zsh session

# Disable auto-activation of skyvenv in timbox
export BOX_NO_SKYVENV=1

# Prefer modern Homebrew toolchain in all zsh sessions (interactive + non-interactive).
# This avoids falling back to legacy /usr/local/bin/git (2.23) which breaks gpg.format=ssh.
typeset -U path
path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
export PATH

# Prevent gh CLI from preferring stale/invalid env token over keyring auth.
unset GITHUB_TOKEN

# scm_breeze helper functions
# These are needed because Claude Code's shell snapshots capture the git wrapper
# functions but not their dependencies from scm_breeze
function token_quote {
  local quoted
  quoted=()
  for token; do
    quoted+=( "$(printf '%q' "$token")" )
  done
  printf '%s\n' "${quoted[*]}"
}

function _safe_eval() {
  eval $(token_quote "$@")
}
