# ============================================================================
# TOOL INITIALIZATION
# ============================================================================

# Prefer modern Homebrew toolchain in bash login shells as well.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# scm_breeze (git shortcuts)
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"
