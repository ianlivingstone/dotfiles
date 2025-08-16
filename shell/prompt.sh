#!/usr/bin/env zsh
# Shell prompt and status configuration
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Shell status function
shell_status() {
    # Only show for interactive shells
    [[ $- != *i* ]] && return
    
    local user_host="$(whoami)@$(hostname -s)"
    local current_dir="$(pwd | sed "s|$HOME|~|")"
    local uptime_info="$(uptime | sed 's/.*up //' | sed 's/users.*//' | sed 's/,.*load.*//' | xargs)"
    local current_time="$(date '+%H:%M')"
    
    # Git info if in a git repository
    local git_info=""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch="$(git branch --show-current 2>/dev/null || echo 'detached')"
        local git_status=""
        if [[ -z "$(git status --porcelain 2>/dev/null)" ]]; then
            git_status="✓"
        else
            git_status="±"
        fi
        git_info="📦 $branch $git_status | "
    fi
    
    echo "🏠 $user_host $current_dir | ⏱ $uptime_info | $git_info🕐 $current_time"
}

# Initialize starship prompt
eval "$(starship init zsh)"

# Show status on new interactive shell
if [[ $- == *i* ]]; then
    # Run security check (warns about issues but doesn't auto-fix)
    quick_security_check
    
    shell_status
    echo "💡 Run 'dotfiles status' to check your complete setup status"
fi