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

# Color codes
RESET='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'

# Determine thinking mode indicator based on settings
if [ "$thinking_enabled" = "true" ]; then
    thinking_indicator="🧠"
else
    thinking_indicator=""
fi

# Calculate approximate context usage
context_indicator=""
# Use transcript_path if it's recent, otherwise fall back to most recent JSONL
target_jsonl=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Check if the transcript file was modified in the last 5 minutes (300 seconds)
    file_age=$(($(date +%s) - $(stat -c %Y "$transcript_path" 2>/dev/null || stat -f %m "$transcript_path" 2>/dev/null || echo 0)))
    if [ "$file_age" -lt 300 ]; then
        # File is recent, use it (for multiple session support)
        target_jsonl="$transcript_path"
    fi
fi

# If no valid transcript_path or it's old, use the most recent JSONL
if [ -z "$target_jsonl" ]; then
    target_jsonl=$(ls -t $HOME/.claude/projects/*/*.jsonl 2>/dev/null | head -1)
fi

if [ -n "$target_jsonl" ] && [ -f "$target_jsonl" ]; then
    # Get the most recent assistant message's input token count
    # This represents the actual context size for that request
    recent_tokens=$(tail -20 "$target_jsonl" 2>/dev/null | \
        jq -r 'select(.type == "assistant") | .message.usage |
        (.input_tokens + .cache_read_input_tokens)' 2>/dev/null | \
        tail -1)

    # Calculate actual percentage of 200k context window
    # Showing context used, not remaining
    if [ -n "$recent_tokens" ] && [ "$recent_tokens" -gt 0 ]; then
        # Calculate percentage (assuming 200k context window)
        percentage=$((recent_tokens * 100 / 200000))

        # Only show if using more than 10% of context
        if [ "$percentage" -gt 10 ]; then
            context_indicator="${percentage}%"
        fi

        # Cap at 99% if not exceeding (since we're approximating)
        if [ "$percentage" -gt 99 ] && [ "$exceeds_200k" != "true" ]; then
            context_indicator="99%"
        fi
    fi
fi

# Don't override with MAX even if exceeds_200k is true
# The percentage will show the actual usage

# Build statusline
echo -en "${BLUE}${model}${RESET}"
if [ -n "$thinking_indicator" ]; then
    echo -en " ${thinking_indicator}"
fi
if [ -n "$context_indicator" ]; then
    echo -en "  ${CYAN}${context_indicator}${RESET}"
fi
echo -en "  ${GREEN}\$${cost_formatted}${RESET}"
echo -en "  ${YELLOW}${dir_name}${RESET}"
