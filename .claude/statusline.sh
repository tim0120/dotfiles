#!/usr/bin/env bash

# Read JSON from stdin
input=$(cat)

# Check if thinking is currently active by examining recent JSONL logs
thinking_enabled="false"
if [ -f "$HOME/.claude/detect_thinking_mode.sh" ]; then
    thinking_enabled=$($HOME/.claude/detect_thinking_mode.sh)
else
    # Fallback to checking settings.json if detection script doesn't exist
    if [ -f "$HOME/.claude/settings.json" ]; then
        thinking_enabled=$(cat $HOME/.claude/settings.json | grep -o '"alwaysThinkingEnabled"\s*:\s*true' | wc -l)
        if [ "$thinking_enabled" -gt 0 ]; then
            thinking_enabled="true"
        else
            thinking_enabled="false"
        fi
    fi
fi

# Parse JSON using jq (fallback to simple parsing if jq not available)
if command -v jq &> /dev/null; then
    cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
    duration=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
    lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
    lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
    model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
    cwd=$(echo "$input" | jq -r '.cwd // "~"')
    exceeds_200k=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')
    transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')
else
    # Fallback parsing without jq
    cost=$(echo "$input" | grep -o '"total_cost_usd":[0-9.]*' | cut -d: -f2)
    duration=$(echo "$input" | grep -o '"total_duration_ms":[0-9]*' | cut -d: -f2)
    lines_added=$(echo "$input" | grep -o '"total_lines_added":[0-9]*' | cut -d: -f2)
    lines_removed=$(echo "$input" | grep -o '"total_lines_removed":[0-9]*' | cut -d: -f2)
    model=$(echo "$input" | grep -o '"display_name":"[^"]*"' | cut -d'"' -f4)
    cwd=$(echo "$input" | grep -o '"cwd":"[^"]*"' | cut -d'"' -f4)
    exceeds_200k=$(echo "$input" | grep -o '"exceeds_200k_tokens":[^,}]*' | cut -d: -f2)
    transcript_path=$(echo "$input" | grep -o '"transcript_path":"[^"]*"' | cut -d'"' -f4)

    cost=${cost:-0}
    duration=${duration:-0}
    lines_added=${lines_added:-0}
    lines_removed=${lines_removed:-0}
    model=${model:-Unknown}
    cwd=${cwd:-~}
    exceeds_200k=${exceeds_200k:-false}
    transcript_path=${transcript_path:-}
fi

# Format cost to 2 decimal places
cost_formatted=$(printf "%.2f" "$cost" 2>/dev/null || echo "$cost")

# Get directory name (handle root and empty cases)
dir_name="${cwd##*/}"
if [ -z "$dir_name" ] || [ "$cwd" = "/" ]; then
    dir_name="$cwd"
fi

# Replace home directory with ~
if [ "$cwd" = "$HOME" ]; then
    dir_name="~"
fi

# Color codes (single dimmed color for everything)
RESET='\033[0m'
DIM='\033[2;37m'

# Determine thinking mode indicator based on settings
if [ "$thinking_enabled" = "true" ]; then
    thinking_indicator="🧠"
else
    thinking_indicator=""
fi

# Detect if we're on a remote machine via SSH
remote_host=""
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    # Get hostname (short form)
    remote_host=$(hostname -s 2>/dev/null || hostname 2>/dev/null)
fi

# Get git branch and dirty status if in a git repository
git_branch=""
git_dirty=""
if command -v git &> /dev/null; then
    # Change to the cwd directory and check for git branch
    if [ -d "$cwd" ]; then
        branch=$(cd "$cwd" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [ -n "$branch" ]; then
            git_branch="$branch"
            # Check if there are uncommitted changes (staged or unstaged)
            if [ -n "$(cd "$cwd" 2>/dev/null && git status --porcelain 2>/dev/null)" ]; then
                git_dirty="*"
            fi
        fi
    fi
fi

# Build statusline (all one color)
echo -en "${DIM}${model}"
if [ -n "$thinking_indicator" ]; then
    echo -en " ${thinking_indicator}"
fi
if [ -n "$remote_host" ]; then
    echo -en "  @${remote_host}:${dir_name}"
else
    echo -en "  ${dir_name}"
fi
if [ -n "$git_branch" ]; then
    echo -en " (${git_branch}${git_dirty})"
fi
echo -en "${RESET}"
