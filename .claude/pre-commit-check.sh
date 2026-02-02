#!/bin/bash
# Claude PreToolUse hook - checks staged files before git commit
# This runs BEFORE the git pre-commit hook, giving Claude a chance to fix issues

# Read the tool input from stdin
INPUT=$(cat)

# Only check if this is a git commit command
if ! echo "$INPUT" | grep -qE '"command".*git.*commit'; then
    exit 0
fi

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    exit 0
fi

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)
if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

ISSUES=""

# Build patterns dynamically to avoid triggering pre-commit hook on this file
HOME_PATH_PATTERN="$(printf '/%s/[a-zA-Z0-9_-]+|/%s/[a-zA-Z0-9_-]+' 'Users' 'home')"

for FILE in $STAGED_FILES; do
    [ -f "$FILE" ] || continue

    # Check for hardcoded home paths
    if grep -E "$HOME_PATH_PATTERN" "$FILE" 2>/dev/null | grep -vE '(\$USER|\$HOME|\${|example)' > /dev/null; then
        ISSUES="$ISSUES\n- Hardcoded home path in: $FILE"
    fi

    # Check for API keys
    if grep -E "(sk-ant-|sk-[a-zA-Z0-9]{48}|AKIA[0-9A-Z]{16})" "$FILE" > /dev/null 2>&1; then
        ISSUES="$ISSUES\n- API key detected in: $FILE"
    fi

    # Check for private keys
    if grep -E "BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY" "$FILE" > /dev/null 2>&1; then
        ISSUES="$ISSUES\n- Private key in: $FILE"
    fi

    # Check for passwords with values
    if grep -iE "(password|passwd|pwd)\s*[:=]\s*['\"][^'\"]{8,}" "$FILE" 2>/dev/null | grep -v "your_password" > /dev/null; then
        ISSUES="$ISSUES\n- Possible password in: $FILE"
    fi

    # Check for auth tokens
    if grep -iE "(auth_token|bearer|access_token)\s*[:=]\s*['\"][a-zA-Z0-9_-]{20,}" "$FILE" > /dev/null 2>&1; then
        ISSUES="$ISSUES\n- Auth token in: $FILE"
    fi
done

if [ -n "$ISSUES" ]; then
    echo "SENSITIVE CONTENT DETECTED - please fix before committing:"
    echo -e "$ISSUES"
    echo ""
    echo "Suggestions:"
    echo "  - Replace hardcoded paths with \$HOME or ~"
    echo "  - Move secrets to .env (gitignored)"
    echo "  - Use environment variables for credentials"
    exit 1
fi

exit 0
