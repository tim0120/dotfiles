# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS. Files are version-controlled in `~/.dotfiles/` and symlinked to `~/` via `install.sh`. The repo uses a split-config approach where sensitive/personal information is kept in separate gitignored files.

## Key Architecture Patterns

### Split Configuration Strategy

**Public configs** (committed):
- `.gitconfig` - Contains only aliases, LFS settings, and credential helper
- `.zshrc`, `.bash_profile` - Shell configs with `$HOME` instead of hardcoded paths
- `.claude/settings.template.json` - Example settings

**Private configs** (gitignored):
- `.gitconfig.local` - User name and email (included via `[include]` directive)
- `.claude/settings.json` - Actual Claude Code settings (copied from template on install)
- `.env` - Environment variables and secrets

### Symlink Management

The `install.sh` script:
1. Backs up existing files to timestamped `~/.dotfiles_backup_YYYYMMDD_HHMMSS/`
2. Creates symlinks: `~/.zshrc` → `~/.dotfiles/.zshrc`
3. Handles both files and directories (`.config/nvim`, `.claude/`)
4. Does NOT symlink `.claude/settings.json` (Claude Code writes to it)

When editing configs, you're editing the source in `~/.dotfiles/`, not copies.

## Setup and Testing

**Fresh install:**
```bash
git clone git@github.com:tim0120/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh
```

**After install, create private configs:**
```bash
# Git identity
cat > ~/.gitconfig.local << EOF
[user]
  name = Your Name
  email = your@email.com
EOF

# Environment secrets (optional)
touch ~/.env
```

**Testing changes:**
- Edit files in `~/.dotfiles/`
- Changes take effect immediately (symlinks)
- Test in new terminal or `source ~/.zshrc`

## Claude Code Integration

**Statusline scripts** (in `.claude/`):
- `statusline.sh` - Shows model, thinking mode (🧠), context %, cost, directory
- `detect_thinking_mode.sh` - Checks recent JSONL logs for thinking blocks
- `claude-notification.sh` - macOS notification when tasks complete

**Settings approach:**
- Template shows recommended config
- Actual `settings.json` stays local (users customize it)
- Scripts are symlinked and version controlled

## Python Environment

Uses **uv** (not conda). Config in `.config/uv/uv.toml`:
- `index-strategy = "unsafe-best-match"` for speed
- `compile-bytecode = true` for faster startups
- System Python: 3.13.2 from Homebrew

## Adding New Dotfiles

1. Move file from `~/` to `~/.dotfiles/`
2. Replace hardcoded paths with `$HOME` or `~`
3. Add symlink creation to `install.sh`
4. If file contains secrets, add to `.gitignore` and create split-config approach
5. Commit changes (but don't push - user approval required)

## Organizing Config Files

Use section headers for clarity:
```bash
# ============================================================================
# SECTION NAME
# ============================================================================
```

**Standard order for shell RC files:**
1. Early init (brew, instant prompt)
2. oh-my-zsh config
3. Environment variables
4. PATH configuration
5. Aliases
6. Functions
7. Tool initialization
8. Shell behavior

Keep comments minimal but explanatory.
