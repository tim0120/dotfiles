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
