# .zshenv - Sourced for ALL zsh shells (interactive and non-interactive)
# This file is loaded before .zshrc and for every zsh session

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
