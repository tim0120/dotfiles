# dotfiles

Personal dotfiles managed with symlinks.

## Setup

Clone this repo to `~/.dotfiles`:

```bash
git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/.dotfiles
```

Run the install script to create symlinks:

```bash
~/.dotfiles/install.sh
```

## What's included

- `.zshrc` - Zsh configuration
- `.gitconfig` - Git configuration
- Add more as needed

## How it works

The `install.sh` script creates symlinks from your home directory to the files in this repo. This means you can edit files in `~/.dotfiles` and have changes take effect immediately, while keeping everything version controlled.

## Adding new dotfiles

1. Move the file from `~/` to `~/.dotfiles/`
2. Add it to the `install.sh` script
3. Run the install script to create the symlink
4. Commit and push

## Manual setup

If you prefer to create symlinks manually:

```bash
ln -sf ~/.dotfiles/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig
```
