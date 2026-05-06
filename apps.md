# Apps to install on a new machine

These aren't managed by Homebrew — download directly or from the App Store.

## Essentials first
- [ ] [Ghostty](https://ghostty.org) — terminal
- [ ] [1Password](https://1password.com) — passwords (do this before anything else)
- [ ] [Tailscale](https://tailscale.com) — VPN

## Dev
- [ ] [Claude](https://claude.ai/download) — AI assistant
- [ ] [Codex](https://openai.com/codex) — AI coding
- [ ] [Cursor](https://cursor.com) — AI editor
- [ ] [Zed](https://zed.dev) — editor

## Productivity
- [ ] [Raycast](https://raycast.com) — launcher (replaces Spotlight)
- [ ] [Rectangle](https://rectangleapp.com) — window management
- [ ] [Maccy](https://maccy.app) — clipboard history
- [ ] [AltTab](https://alt-tab-macos.netlify.app) — better cmd-tab
- [ ] [Granola](https://granola.ai) — meeting notes
- [ ] [Flux](https://justgetflux.com) — screen warmth

## Communication
- [ ] [Slack](https://slack.com/downloads/mac)
- [ ] WhatsApp — App Store

## Knowledge & notes
- [ ] [Obsidian](https://obsidian.md)
- [ ] [Zotero](https://zotero.org)

## Media
- [ ] [Spotify](https://spotify.com/download)

## Browsers
- [ ] [Zen Browser](https://zen-browser.app)

## After apps are installed
- [ ] Sign into iCloud (syncs contacts, calendar, notes, keychain)
- [ ] Sign into 1Password and install browser extension
- [ ] Clone dotfiles: `git clone git@github.com:tim0120/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh`
- [ ] Generate new SSH key: `ssh-keygen -t ed25519 -C "your@email.com"` and add to GitHub
- [ ] Create `~/.gitconfig.local` with work email/name
- [ ] Create `~/.env` with API keys (EXA, TAVILY, ANTHROPIC, etc.)
- [ ] Install zinit: `bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"`
- [ ] Run `brew bundle` from `~/.dotfiles`
- [ ] Install Claude Code: `npm install -g @anthropic-ai/claude-code`
