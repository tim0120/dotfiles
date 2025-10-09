#!/bin/bash

# Claude Code Task Completion Notification Script
# This script shows a Mac notification with sound when Claude finishes a task

# Play notification sound (using system sound)
afplay /System/Library/Sounds/Glass.aiff

# Show macOS notification
osascript -e 'display notification "Claude has finished working on your task!" with title "Claude Code" sound name "Glass"'

# Optional: Log the completion time
echo "$(date): Claude task completed" >> "$HOME/.claude/notification.log"
