#!/usr/bin/env bash
# View recent Claude Code hook execution logs
# Part of dotfiles Claude Code harness

set -euo pipefail

# Configuration
LOG_FILE="$HOME/.claude/hook-output.log"
DEFAULT_LINES=50

# Get number of lines to show (default 50)
lines="${1:-$DEFAULT_LINES}"

# Validate input
if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Invalid number of lines: $lines"
    echo "Usage: $0 [lines]"
    exit 1
fi

# Check if log file exists
if [[ ! -f "$LOG_FILE" ]]; then
    echo "ℹ️  No hook logs found"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Hooks will create this file when they run."
    exit 0
fi

# Get log file size
log_lines=$(wc -l < "$LOG_FILE" | tr -d ' ')

# Header
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Claude Code Hook Execution Log"
if [[ $log_lines -le $lines ]]; then
    echo "Showing all $log_lines lines"
else
    echo "Last $lines lines (of $log_lines total)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Display log
tail -n "$lines" "$LOG_FILE"

# Footer
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $log_lines -le $lines ]]; then
    echo "Total: $log_lines hook executions shown (all)"
else
    echo "Total: $lines of $log_lines hook executions shown"
fi
echo "Log file: $LOG_FILE"
echo ""

# Usage hint
if [[ $log_lines -gt $lines ]]; then
    echo "💡 Tip: Use '/show-hook-log $log_lines' to see all logs"
fi
