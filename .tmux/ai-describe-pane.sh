#!/bin/bash

# AI-powered tmux window describer - summarizes all panes in a window

# Configuration
MAX_LINES=50
MAX_CHARS_PER_PANE=2000
DEBOUNCE_SECONDS=120

# Function to generate description using Claude CLI
generate_description() {
    local all_panes_context="$1"

    # Prepare the prompt - short but readable names
    local prompt="Short tmux window name. MAX 18 CHARS. Keep readable but concise.

$all_panes_context

BAD (too long): 'editing tmux config file' 'pollux api testing'
BAD (cryptic): 'plx:api' 'ed:tm.cf' 'nx:au'
GOOD: 'tmux cfg' 'pollux api' 'next auth' 'redis fix' 'user-svc test'

Drop articles/filler. Use lowercase. Output ONLY the name:"

    local description=""

    if command -v llm &> /dev/null; then
        description=$(echo "$prompt" | llm -m gpt-4o-mini -o max_tokens 15 2>/dev/null | grep -v "^$" | head -1 | tr -d '\n"' | cut -c1-18)
        echo "Generated: '$description'" >> /tmp/tmux-ai-debug.log
    fi

    # Fallback if LLM failed or empty
    if [ -z "$description" ]; then
        description="window"
    fi

    echo "$description"
}

# Main execution
main() {
    local force=false
    [ "$1" = "--force" ] && force=true && shift

    local window_index="${1:-$(tmux display-message -p '#I')}"

    # Debounce: skip if ran within last DEBOUNCE_SECONDS for this window
    local lockfile="/tmp/tmux-ai-rename-w${window_index}.lock"
    if [ "$force" = "false" ] && [ -f "$lockfile" ]; then
        local last_run=$(cat "$lockfile")
        local now=$(date +%s)
        if [ $((now - last_run)) -lt $DEBOUNCE_SECONDS ]; then
            exit 0
        fi
    fi
    echo $(date +%s) > "$lockfile"

    # Get all pane IDs in this window
    local pane_ids=$(tmux list-panes -t ":$window_index" -F '#{pane_id}')

    # Build context from all panes
    local all_context=""
    local pane_num=1

    for pane_id in $pane_ids; do
        local current_path=$(tmux display-message -p -t "$pane_id" '#{pane_current_path}')
        local current_cmd=$(tmux display-message -p -t "$pane_id" '#{pane_current_command}')
        local content=$(tmux capture-pane -p -t "$pane_id" -S -$MAX_LINES 2>/dev/null | head -c $MAX_CHARS_PER_PANE)

        # Check for git info
        local git_branch=""
        if git -C "$current_path" rev-parse --git-dir > /dev/null 2>&1; then
            git_branch=$(git -C "$current_path" branch --show-current 2>/dev/null)
        fi

        all_context="${all_context}
--- Pane $pane_num ---
Directory: $(basename "$current_path")
Command: $current_cmd"
        [ -n "$git_branch" ] && all_context="${all_context}
Git branch: $git_branch"
        all_context="${all_context}
Recent output (last lines):
$(echo "$content" | tail -20)
"
        pane_num=$((pane_num + 1))
    done

    # Skip if basically empty
    if [ ${#all_context} -lt 50 ]; then
        exit 0
    fi

    # Generate and set description
    local description=$(generate_description "$all_context")

    if [ -n "$description" ]; then
        tmux rename-window -t "$window_index" "$description"
        echo "[$(date)] Window $window_index renamed to: $description" >> /tmp/tmux-ai-rename.log
    fi

    # Clear renaming indicator (only if --force was used, meaning user triggered it)
    [ "$force" = "true" ] && tmux set -gu @renaming
}

# Run if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
