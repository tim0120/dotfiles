#!/bin/bash

# Tmux window namer — names windows by git branch (fast, no API calls).
#
# Triggered by tmux hooks (after-select-pane, after-split-window, etc.) and
# manually via prefix+R. Uses git branch as the primary name, with directory
# basename as fallback. Strips user prefixes (tim/, feature/, etc.).
#
# --ai flag available to use LLM-based naming instead (kept but not default).

# Configuration
DEBOUNCE_SECONDS=5
MAX_LINES=50

# ─── Branch-based naming (default) ──────────────────────────────────────────

# Build a short window name from the git branch of the active pane.
# Falls back to directory basename if not in a git repo.
branch_name() {
    local window_index="$1"

    # Use the active pane's path for this window
    local current_path=$(tmux display-message -p -t ":${window_index}" '#{pane_current_path}' 2>/dev/null)
    [ -z "$current_path" ] && echo "window" && return

    # Try git branch
    local branch=""
    if git -C "$current_path" rev-parse --git-dir > /dev/null 2>&1; then
        branch=$(git -C "$current_path" branch --show-current 2>/dev/null)
    fi

    if [ -n "$branch" ]; then
        # Strip common prefixes: tim/, feature/, fix/, etc.
        local name=$(echo "$branch" | sed -E 's|^[^/]+/||')
        # Truncate to 25 chars
        echo "${name:0:25}"
    else
        # No git — use directory name
        echo "$(basename "$current_path")"
    fi
}

# ─── AI-based naming (opt-in via --ai) ──────────────────────────────────────

generate_description() {
    local all_panes_context="$1"

    local prompt="Name this tmux window in 2-3 words (max 25 chars).

Rules:
- Primary signal: use the git branch name (shorten it, drop prefixes like 'tim/')
- Secondary signal: what's actively being worked on (file, feature area)
- Never include repo name, tool names, or actions (no 'pollux', 'claude', 'editing')
- Lowercase, no quotes

$all_panes_context

BAD: 'pollux api tests' 'editing config' 'claude dev setup'
GOOD: 'if-eval' 'sft recipe' 'download-pipe' 'instruct-follow' 'tmux setup'

Output ONLY the short name, nothing else:"

    local description=""

    # Write prompt to temp file to avoid shell/python string escaping issues
    # (pane content can contain quotes, backslashes, box-drawing chars, etc.)
    local prompt_file="/tmp/tmux-ai-prompt-$$.txt"
    printf '%s' "$prompt" > "$prompt_file"

    # Method 1: llm CLI (fastest, uses gpt-4o-mini)
    if [ -z "$description" ] && command -v llm &> /dev/null; then
        description=$(llm -m gpt-4o-mini -o max_tokens 15 < "$prompt_file" 2>/dev/null | grep -v "^$" | head -1 | tr -d '\n"' | cut -c1-25 || true)
    fi

    # Method 2: anthropic SDK via Python (works on devboxes with SDK installed)
    if [ -z "$description" ] && python3 -c "import anthropic" 2>/dev/null; then
        description=$(python3 << PYEOF 2>/dev/null | head -1 | cut -c1-25 || true
import anthropic
prompt = open("$prompt_file", errors="replace").read()
c = anthropic.Anthropic()
r = c.messages.create(model="claude-haiku-4-5-20251001", max_tokens=15, messages=[{"role":"user","content":prompt}])
print(r.content[0].text.strip('"').strip())
PYEOF
)
    fi

    # Method 3: curl to Anthropic API (works anywhere with API key + curl)
    if [ -z "$description" ] && [ -n "$ANTHROPIC_API_KEY" ] && command -v curl &> /dev/null; then
        local escaped_prompt
        escaped_prompt=$(python3 -c "
import json
print(json.dumps(open('$prompt_file', errors='replace').read()))
" 2>/dev/null || echo '""')
        description=$(curl -s --max-time 10 https://api.anthropic.com/v1/messages \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -H "content-type: application/json" \
            -d "{\"model\":\"claude-haiku-4-5-20251001\",\"max_tokens\":25,\"messages\":[{\"role\":\"user\",\"content\":$escaped_prompt}]}" \
            2>/dev/null | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['content'][0]['text'].strip('\"').strip())" 2>/dev/null | head -1 | cut -c1-25 || true)
    fi

    rm -f "$prompt_file"

    echo "Generated: '$description'" >> /tmp/tmux-ai-debug.log

    # Fallback if everything failed
    if [ -z "$description" ]; then
        description="window"
    fi

    echo "$description"
}

# ─── Rename a single window ─────────────────────────────────────────────────

rename_window() {
    local window_index="$1"
    local force="$2"
    local use_ai="$3"

    # Debounce: skip if ran within last DEBOUNCE_SECONDS for this window
    local lockfile="/tmp/tmux-rename-w${window_index}.lock"
    if [ "$force" = "false" ] && [ -f "$lockfile" ]; then
        local last_run=$(cat "$lockfile")
        local now=$(date +%s)
        if [ $((now - last_run)) -lt $DEBOUNCE_SECONDS ]; then
            return 0
        fi
    fi
    echo $(date +%s) > "$lockfile"

    local description=""

    if [ "$use_ai" = "true" ]; then
        # AI path: build full pane context
        local pane_ids=$(tmux list-panes -t ":$window_index" -F '#{pane_id}')
        local all_context=""
        local pane_num=1

        for pane_id in $pane_ids; do
            local current_path=$(tmux display-message -p -t "$pane_id" '#{pane_current_path}')
            local current_cmd=$(tmux display-message -p -t "$pane_id" '#{pane_current_command}')
            local content=$(tmux capture-pane -p -t "$pane_id" -S -$MAX_LINES 2>/dev/null | tail -20)

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
$content
"
            pane_num=$((pane_num + 1))
        done

        if [ ${#all_context} -lt 50 ]; then
            return 0
        fi

        description=$(generate_description "$all_context")
    else
        # Branch path: instant, no API calls
        description=$(branch_name "$window_index")
    fi

    if [ -n "$description" ]; then
        tmux rename-window -t ":$window_index" "$description"
        echo "[$(date)] Window $window_index renamed to: $description" >> /tmp/tmux-ai-rename.log
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
    local force=false
    local all=false
    local use_ai=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --force) force=true; shift ;;
            --all) all=true; shift ;;
            --ai) use_ai=true; shift ;;
            *) break ;;
        esac
    done

    if [ "$all" = "true" ]; then
        local window_indices=$(tmux list-windows -F '#{window_index}')
        for idx in $window_indices; do
            rename_window "$idx" "$force" "$use_ai"
        done
    else
        local window_index="${1:-$(tmux display-message -p '#I')}"
        rename_window "$window_index" "$force" "$use_ai"
    fi

    # Clear renaming indicator (only if --force was used, meaning user triggered it)
    [ "$force" = "true" ] && tmux set -gu @renaming
}

# Run if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
