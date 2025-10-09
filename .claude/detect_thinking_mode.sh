#!/bin/bash

# Find the most recently modified JSONL file (current session)
LATEST_JSONL=$(ls -t $HOME/.claude/projects/*/*.jsonl 2>/dev/null | head -1)

if [ -z "$LATEST_JSONL" ]; then
    # Fallback to default
    echo "false"
    exit 0
fi

# Check if recent assistant messages contain thinking blocks
# Looking at last 30 entries to catch recent activity
HAS_RECENT_THINKING=$(tail -30 "$LATEST_JSONL" 2>/dev/null | \
    jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "thinking") | .type' 2>/dev/null | \
    head -1)

# If we found any thinking blocks in recent messages, thinking mode is enabled
if [ ! -z "$HAS_RECENT_THINKING" ]; then
    echo "true"
else
    echo "false"
fi
