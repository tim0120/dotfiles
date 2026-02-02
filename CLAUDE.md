# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## What This Is

This is **Tim Kostolansky's personal dotfiles** repository. It's a public repo on GitHub (`tim0120/dotfiles`) but configured specifically for one user. The git identity, shell preferences, and tool configs are all Tim's personal settings.

**Key insight**: This repo uses `$HOME` and `~` instead of hardcoded paths like `/Users/timkostolansky`, so the same dotfiles work on:
- Local Mac (`/Users/timkostolansky`)
- GCP dev boxes (`/home/timkostolansky`)
- Any other machine with a different home directory

## Multi-Machine Deployment

These dotfiles are deployed across multiple machines:

| Machine | How to Deploy | How to Update |
|---------|---------------|---------------|
| Local Mac | Already set up | Edit files directly (symlinked) |
| GCP dev boxes | `git clone ... && ./install.sh` | `cd ~/.dotfiles && git pull && ./install.sh` |
| New machines | Same as GCP | Same as GCP |

**Important**: Changes made locally do NOT automatically propagate to remote machines. After pushing changes, you must manually pull and reinstall on each remote:

```bash
# On remote machine
cd ~/.dotfiles && git pull && ./install.sh
```

To add dotfiles setup to dev box provisioning, add this to your provisioning script:
```bash
git clone https://github.com/tim0120/dotfiles.git ~/.dotfiles 2>/dev/null || \
    (cd ~/.dotfiles && git pull)
~/.dotfiles/install.sh
```

## Repository Structure

```
~/.dotfiles/
├── .claude/                    # Claude Code configuration
│   ├── statusline.sh          # Status bar display
│   ├── claude-notification.sh # Sound on task complete
│   ├── claude-sync-hook.sh    # Sync conversations (Stop hook)
│   ├── code-quality-check.sh  # Lint/typecheck (Stop hook)
│   ├── format-on-edit.sh      # Auto-format Python (PostToolUse hook)
│   ├── detect_thinking_mode.sh
│   ├── mcp_settings.json      # MCP server configs (uses env vars)
│   └── settings.template.json # Template for settings.json
├── .config/
│   ├── nvim/                  # Neovim config
│   └── uv/                    # uv (Python) config
├── .git-templates/            # Git hooks for all repos
│   └── hooks/
│       ├── pre-commit         # Blocks secrets, hardcoded paths
│       ├── pre-push           # Prevents force push to main
│       └── commit-msg         # Validates commit messages
├── .gitconfig                 # Git config (includes identity)
├── .gitignore                 # What NOT to commit
├── .zshrc                     # Main shell config
├── .zshenv                    # Shell env (loaded for all shells)
├── .vimrc                     # Vim config
├── install.sh                 # Deployment script
└── CLAUDE.md                  # This file
```

## What Gets Symlinked vs Copied vs Ignored

| File | Treatment | Reason |
|------|-----------|--------|
| `.zshrc`, `.gitconfig`, etc. | Symlinked | Changes in repo appear immediately |
| `.claude/*.sh` | Symlinked | Hook scripts shared across machines |
| `.claude/mcp_settings.json` | Symlinked | MCP config shared (uses `${ENV_VAR}` refs) |
| `.claude/settings.json` | **Copied from template** | Claude Code writes to this file |
| `.env`, `*_key.sh` | **Gitignored** | Contains secrets |
| `.gitconfig.local` | **Gitignored** | Machine-specific overrides |

## Security Model

**Committed (safe)**:
- Git identity uses GitHub noreply email (`39891386+tim0120@users.noreply.github.com`)
- API keys use environment variable references (`${EXA_API_KEY}`)
- All paths use `$HOME` or `~`, never hardcoded usernames

**Gitignored (secrets)**:
- `.env` - API keys and secrets
- `*_key.sh` - Key files
- `.claude/settings.json` - May contain sensitive permissions
- `.gitconfig.local` - Machine-specific overrides

**Pre-commit hook protection**:
- Blocks commits containing API key patterns (`sk-ant-*`, `AKIA*`, etc.)
- Blocks hardcoded home paths (`/Users/username`, `/home/username`)
- Warns on email addresses (except noreply)

## Claude Code Hooks

The `settings.json` references these hooks which MUST exist on all machines:

```json
{
  "hooks": {
    "PreToolUse": [{"matcher": "Bash", "command": "~/.claude/pre-commit-check.sh"}],
    "PostToolUse": [{"matcher": "Edit|Write", "command": "~/.claude/format-on-edit.sh"}],
    "Stop": [
      {"command": "~/.claude/code-quality-check.sh"},
      {"command": "~/.claude/claude-notification.sh"},
      {"command": "~/.claude/claude-sync-hook.sh"}
    ]
  }
}
```

### Security: Pre-commit Check

The `pre-commit-check.sh` hook runs **before** any `git commit` command Claude executes. It scans staged files for:
- Hardcoded home paths (`/Users/xxx`, `/home/xxx`)
- API keys (Anthropic, OpenAI, AWS)
- Private keys
- Passwords and auth tokens

If issues are found, Claude is blocked from committing and told to fix the problems first. This is a Claude-specific safety layer on top of the git pre-commit hook.

If these scripts don't exist, Claude Code will fail with "not found" errors. The `install.sh` script creates symlinks for all of them.

## Common Tasks

### Adding a new dotfile
1. Move file to `~/.dotfiles/`
2. Replace any hardcoded paths with `$HOME` or `~`
3. Add symlink creation to `install.sh`
4. If it contains secrets, add to `.gitignore` instead

### Adding a new Claude Code hook
1. Create script in `~/.dotfiles/.claude/`
2. Make it executable and add graceful fallbacks (check if dependencies exist)
3. Add symlink creation to `install.sh`
4. Reference it in `settings.json` (which stays local)

### Deploying to a new machine
```bash
# Clone and install
git clone https://github.com/tim0120/dotfiles.git ~/.dotfiles
~/.dotfiles/install.sh

# Create local secrets file
touch ~/.env
# Add API keys: EXA_API_KEY, TAVILY_API_KEY, etc.
```

### Updating remote machines after local changes
```bash
# Push from local
cd ~/.dotfiles && git add -A && git commit -m "Update" && git push

# Pull on each remote
ssh <remote> "cd ~/.dotfiles && git pull && ./install.sh"
```
