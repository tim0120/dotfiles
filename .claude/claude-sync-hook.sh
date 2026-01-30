#!/bin/bash
# Claude Code hook: Sync conversations on session end
# Add to ~/.claude/settings.json under hooks.Stop

SYNC_SCRIPT="$HOME/Developer/claude-sync/sync.py"
LOG_FILE="$HOME/.claude-sync/sync.log"

# Only run if sync script exists
if [[ -f "$SYNC_SCRIPT" ]]; then
    # Run sync in background to not block Claude exit
    (
        echo "$(date -Iseconds) Starting sync..." >> "$LOG_FILE"
        python3 "$SYNC_SCRIPT" --push >> "$LOG_FILE" 2>&1
        echo "$(date -Iseconds) Sync complete" >> "$LOG_FILE"
    ) &
fi
