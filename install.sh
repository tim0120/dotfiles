#!/bin/bash

# Dotfiles installation script
# Creates symlinks from home directory to dotfiles repo

set -e

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing dotfiles...${NC}"

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}Backup directory: $BACKUP_DIR${NC}"

# Function to safely create symlink
create_symlink() {
    local source="$1"
    local target="$2"

    # If target exists and is not a symlink, back it up
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo -e "${YELLOW}Backing up existing $target${NC}"
        mv "$target" "$BACKUP_DIR/"
    fi

    # Remove existing symlink if it exists
    if [ -L "$target" ]; then
        rm "$target"
    fi

    # Create symlink
    ln -sf "$source" "$target"
    echo -e "${GREEN}✓ Linked $target${NC}"
}

# Symlink dotfiles
create_symlink "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"

# Symlink neovim config directory
mkdir -p "$HOME/.config"
create_symlink "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

# Symlink uv config
if [ -d "$DOTFILES_DIR/.config/uv" ]; then
    create_symlink "$DOTFILES_DIR/.config/uv" "$HOME/.config/uv"
fi

# Symlink Karabiner-Elements config (Goku .edn file)
if [ -f "$DOTFILES_DIR/.config/karabiner.edn" ]; then
    create_symlink "$DOTFILES_DIR/.config/karabiner.edn" "$HOME/.config/karabiner.edn"
fi

# Copy Karabiner-Elements JSON config (cannot be symlinked — Karabiner writes to it)
# Gaming mode and other manual additions live here; do NOT run goku or it will be overwritten
if [ -f "$DOTFILES_DIR/.config/karabiner/karabiner.json" ]; then
    mkdir -p "$HOME/.config/karabiner"
    if [ ! -f "$HOME/.config/karabiner/karabiner.json" ]; then
        echo -e "${GREEN}Copying karabiner.json${NC}"
        cp "$DOTFILES_DIR/.config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
    else
        echo -e "${YELLOW}Skipping karabiner.json (already exists — update manually if needed)${NC}"
    fi
fi

# Symlink Starship prompt config
if [ -f "$DOTFILES_DIR/.config/starship.toml" ]; then
    create_symlink "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
fi

# Symlink tmux config and scripts
if [ -f "$DOTFILES_DIR/.tmux.conf" ]; then
    create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
fi

if [ -d "$DOTFILES_DIR/.tmux" ]; then
    create_symlink "$DOTFILES_DIR/.tmux" "$HOME/.tmux"
fi

# Symlink git templates
if [ -d "$DOTFILES_DIR/.git-templates" ]; then
    create_symlink "$DOTFILES_DIR/.git-templates" "$HOME/.git-templates"
fi

# Symlink Claude config (only safe files)
# Note: API keys, cache files, and settings.json are NOT symlinked
if [ -d "$DOTFILES_DIR/.claude" ]; then
    mkdir -p "$HOME/.claude"

    # Symlink statusline scripts
    if [ -f "$DOTFILES_DIR/.claude/statusline.sh" ]; then
        create_symlink "$DOTFILES_DIR/.claude/statusline.sh" "$HOME/.claude/statusline.sh"
        chmod +x "$HOME/.claude/statusline.sh"
    fi

    if [ -f "$DOTFILES_DIR/.claude/detect_thinking_mode.sh" ]; then
        create_symlink "$DOTFILES_DIR/.claude/detect_thinking_mode.sh" "$HOME/.claude/detect_thinking_mode.sh"
        chmod +x "$HOME/.claude/detect_thinking_mode.sh"
    fi

    # Symlink notification script
    if [ -f "$DOTFILES_DIR/.claude/claude-notification.sh" ]; then
        create_symlink "$DOTFILES_DIR/.claude/claude-notification.sh" "$HOME/.claude/claude-notification.sh"
        chmod +x "$HOME/.claude/claude-notification.sh"
    fi

    # Symlink hook scripts
    if [ -f "$DOTFILES_DIR/.claude/claude-sync-hook.sh" ]; then
        create_symlink "$DOTFILES_DIR/.claude/claude-sync-hook.sh" "$HOME/.claude/claude-sync-hook.sh"
        chmod +x "$HOME/.claude/claude-sync-hook.sh"
    fi

    if [ -f "$DOTFILES_DIR/.claude/code-quality-check.sh" ]; then
        create_symlink "$DOTFILES_DIR/.claude/code-quality-check.sh" "$HOME/.claude/code-quality-check.sh"
        chmod +x "$HOME/.claude/code-quality-check.sh"
    fi

    if [ -f "$DOTFILES_DIR/.claude/format-on-edit.sh" ]; then
        create_symlink "$DOTFILES_DIR/.claude/format-on-edit.sh" "$HOME/.claude/format-on-edit.sh"
        chmod +x "$HOME/.claude/format-on-edit.sh"
    fi

    if [ -f "$DOTFILES_DIR/.claude/pre-commit-check.sh" ]; then
        create_symlink "$DOTFILES_DIR/.claude/pre-commit-check.sh" "$HOME/.claude/pre-commit-check.sh"
        chmod +x "$HOME/.claude/pre-commit-check.sh"
    fi

    # Symlink MCP settings
    if [ -f "$DOTFILES_DIR/.claude/mcp_settings.json" ]; then
        create_symlink "$DOTFILES_DIR/.claude/mcp_settings.json" "$HOME/.claude/mcp_settings.json"
    fi

    # Symlink commands directory if it exists
    if [ -d "$DOTFILES_DIR/.claude/commands" ]; then
        create_symlink "$DOTFILES_DIR/.claude/commands" "$HOME/.claude/commands"
    fi

    # Copy settings template if settings.json doesn't exist
    # Note: We DON'T symlink settings.json because Claude Code writes to it
    if [ ! -f "$HOME/.claude/settings.json" ] && [ -f "$DOTFILES_DIR/.claude/settings.template.json" ]; then
        echo -e "${YELLOW}Creating settings.json from template${NC}"
        cp "$DOTFILES_DIR/.claude/settings.template.json" "$HOME/.claude/settings.json"
    fi
fi

echo -e "${GREEN}✓ Dotfiles installed successfully!${NC}"
echo -e "${YELLOW}Note: Your original files are backed up in $BACKUP_DIR${NC}"

# Remind user about personal config files
if [ ! -f "$HOME/.gitconfig.local" ]; then
    echo ""
    echo -e "${YELLOW}Don't forget to create ~/.gitconfig.local with your personal info:${NC}"
    echo -e "  [user]"
    echo -e "    name = Your Name"
    echo -e "    email = your@email.com"
fi

if [ ! -f "$HOME/.env" ]; then
    echo ""
    echo -e "${YELLOW}Tip: Create ~/.env for environment-specific secrets${NC}"
fi
