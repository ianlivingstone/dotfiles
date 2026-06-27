#!/usr/bin/env zsh
# Shell prompt and status configuration
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Source shared utilities
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")" && pwd)"
source "$SHELL_DIR/utils.sh"

# Shell status function
shell_status() {
    # Only show for interactive shells
    [[ $- != *i* ]] && return
    
    # Use zsh builtins instead of forking whoami/hostname/pwd|sed.
    # (Dropped the uptime segment: it spawned 5 processes for marginal value.)
    local user_host="${USER}@${HOST%%.*}"
    local current_dir="${PWD/#$HOME/~}"
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
    
    # Battery info if available
    local battery_info=""
    if battery_status=$(get_battery_status 2>/dev/null); then
        battery_info="$battery_status | "
    fi
    
    echo "🏠 $user_host $current_dir | $git_info$battery_info🕐 $current_time"
}

# Initialize starship prompt — cache `starship init zsh` instead of forking
# starship on every shell. Regenerate only when the starship binary changes.
if command -v starship >/dev/null 2>&1; then
    local starship_bin="$(command -v starship)"
    local starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/starship_init.zsh"
    if [[ ! -s "$starship_cache" || "$starship_bin" -nt "$starship_cache" ]]; then
        mkdir -p "${starship_cache:h}"
        # Write atomically: a partial/failed init script must never be sourced.
        local starship_tmp="${starship_cache}.$$"
        if starship init zsh > "$starship_tmp" 2>/dev/null && [[ -s "$starship_tmp" ]]; then
            mv -f "$starship_tmp" "$starship_cache"
        else
            rm -f "$starship_tmp"
        fi
    fi
    [[ -s "$starship_cache" ]] && source "$starship_cache"
fi

# Show status on new interactive shell
if [[ $- == *i* ]]; then
    # If we're in a git repo, warm `git status` in the background now (disowned, no
    # output) so the fsmonitor daemon and untracked cache are primed before your first
    # command. The first status per repo/boot is a cold full scan; paying it off the
    # prompt while you read this banner means the first prompt's git module is already fast.
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        (git status --porcelain &>/dev/null &) &>/dev/null
    fi

    # Run the security check at most once per 12h across all shells. The result is
    # process-local, so without this every new terminal re-paid ~72ms. Tradeoff: a
    # newly-introduced permission problem may go unwarned for up to 12h in fresh shells;
    # run `validate_security_permissions` (or `security_status`) on demand to force it.
    # Re-run the security check when any watched key/config file changes, with a 24h
    # backstop. mtime catches newly added keys/configs immediately; the backstop covers
    # permission drift from chmod, which updates ctime (not mtime) and so is invisible to -nt.
    local sec_stamp="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/security_check.stamp"
    local _xc="${XDG_CONFIG_HOME:-$HOME/.config}"
    setopt EXTENDEDGLOB
    local -a _sec_watch
    _sec_watch=(
        "$_xc"/ssh/machine.config(N) "$_xc"/git/machine.config(N) "$_xc"/gpg/machine.config(N)
        ~/.ssh(N) ~/.gnupg(N) ~/.ssh/id_*(N)
    )
    local _sec_run=0
    if [[ -z $sec_stamp(#qNmh-24) ]]; then
        _sec_run=1                       # missing, or older than the 24h backstop
    else
        local _f
        for _f in $_sec_watch; do
            [[ "$_f" -nt "$sec_stamp" ]] && { _sec_run=1; break; }
        done
    fi
    if (( _sec_run )); then
        quick_security_check
        mkdir -p "${sec_stamp:h}" && touch "$sec_stamp"
    fi
    unsetopt EXTENDEDGLOB

    shell_status
    echo "💡 Run 'dotfiles status' to check your complete setup status"
fi