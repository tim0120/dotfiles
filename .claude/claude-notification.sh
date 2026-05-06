#!/bin/bash
# Fires on Claude Code Stop event.
# Writes BEL directly to the terminal so Ghostty triggers its notification.

printf '\a' > /dev/tty 2>/dev/null || printf '\a'
date +"%H:%M:%S.%3N stop-hook fired" >> "$HOME/.claude/notification-timing.log"
exit 0
