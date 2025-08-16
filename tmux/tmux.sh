#!/usr/bin/env zsh
# Tmux utility functions
# Sources shell modules to provide battery status and other utilities

# Get the directory containing the actual shell modules
# Derive the dotfiles directory from this script's location, resolving symlinks
SCRIPT_PATH="${BASH_SOURCE[0]:-${(%):-%N}}"

# Resolve symlinks to get the real path
if [[ -L "$SCRIPT_PATH" ]]; then
    local target="$(readlink "$SCRIPT_PATH")"
    # Handle relative symlinks by making them absolute
    if [[ "$target" != /* ]]; then
        SCRIPT_PATH="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)/$target"
    else
        SCRIPT_PATH="$target"
    fi
fi

TMUX_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
DOTFILES_DIR="$(dirname "$TMUX_DIR")"
SHELL_DIR="$DOTFILES_DIR/shell"

# Load utility functions (contains get_battery_status)
if [[ -f "$SHELL_DIR/utils.sh" ]]; then
    source "$SHELL_DIR/utils.sh"
else
    echo "Shell utils not found" >&2
    exit 1
fi

# Load shell functions (contains other utilities)
if [[ -f "$SHELL_DIR/functions.sh" ]]; then
    source "$SHELL_DIR/functions.sh"
fi

# Call the requested function if provided as argument
if [[ $# -gt 0 ]]; then
    "$@"
fi