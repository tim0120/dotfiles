#!/bin/bash
# PostToolUse hook: Auto-format Python files after edit
# Only runs on .py files, silent if ruff not available

FILE_PATH="$CLAUDE_TOOL_ARG_FILE_PATH"

# Only process Python files
if [[ "$FILE_PATH" == *.py ]] && [[ -f "$FILE_PATH" ]]; then
    # Check if ruff is available
    if command -v ruff &> /dev/null; then
        ruff format "$FILE_PATH" --quiet 2>/dev/null
    fi
fi
