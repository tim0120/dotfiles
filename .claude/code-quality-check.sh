#!/bin/bash
# Stop hook: Run code quality checks when Claude finishes
# Runs lint + typecheck, reports issues

# Skip if running from home directory (would scan everything)
if [[ "$PWD" == "$HOME" ]]; then
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Running code quality checks..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUES=0

# Check if we're in a Python project
if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || ls *.py &>/dev/null 2>&1; then

    # Ruff lint
    if command -v ruff &> /dev/null; then
        echo ""
        echo "📋 Ruff lint:"
        RUFF_OUTPUT=$(ruff check . 2>&1)
        RUFF_EXIT=$?
        if [[ $RUFF_EXIT -ne 0 ]]; then
            echo "$RUFF_OUTPUT" | head -20
            RUFF_COUNT=$(echo "$RUFF_OUTPUT" | grep -c "^")
            if [[ $RUFF_COUNT -gt 20 ]]; then
                echo "... and more ($(($RUFF_COUNT - 20)) lines truncated)"
            fi
            ISSUES=1
        else
            echo "✅ No lint issues"
        fi
    fi

    # Pyright typecheck
    if command -v pyright &> /dev/null; then
        echo ""
        echo "🔷 Pyright typecheck:"
        PYRIGHT_OUTPUT=$(pyright 2>&1)
        PYRIGHT_EXIT=$?
        if [[ $PYRIGHT_EXIT -ne 0 ]]; then
            echo "$PYRIGHT_OUTPUT" | grep -E "(error|warning):" | head -15
            ERROR_COUNT=$(echo "$PYRIGHT_OUTPUT" | grep -c "error:")
            if [[ $ERROR_COUNT -gt 0 ]]; then
                echo ""
                echo "Found $ERROR_COUNT type error(s)"
                ISSUES=1
            fi
        else
            echo "✅ No type errors"
        fi
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ $ISSUES -eq 0 ]]; then
        echo "✅ All checks passed!"
    else
        echo "⚠️  Issues found - consider fixing before commit"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "Not a Python project, skipping checks"
fi
