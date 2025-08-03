# Shared utility functions for dotfiles shell modules

# Get the directory containing shell modules, resolving symlinks properly
# Usage: get_shell_dir [script_path]
# If script_path is not provided, uses the calling script's path
get_shell_dir() {
    local script_path="${1:-${(%):-%N}}"
    
    # If SHELL_DIR is already set (from .zshrc), use it
    if [[ -n "$SHELL_DIR" ]]; then
        echo "$SHELL_DIR"
        return 0
    fi
    
    # Resolve symlinks to get the real path
    if [[ -L "$script_path" ]]; then
        local target="$(readlink "$script_path")"
        # Handle relative symlinks by making them absolute
        if [[ "$target" != /* ]]; then
            script_path="$(cd "$(dirname "$script_path")" && pwd)/$target"
        else
            script_path="$target"
        fi
    fi
    
    # Get the directory containing the script
    cd "$(dirname "$script_path")" && pwd
}

# Load a config file with fallback value
# Usage: load_config config_file variable_name fallback_value
load_config() {
    local config_file="$1"
    local var_name="$2" 
    local fallback="$3"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        eval "$var_name=\"$fallback\""
    fi
}

# Add directory to PATH if not already present
# Usage: add_to_path /path/to/directory
add_to_path() {
    local dir_path="$1"
    if [[ -d "$dir_path" ]] && [[ ":$PATH:" != *":$dir_path:"* ]]; then
        export PATH="$dir_path:$PATH"
    fi
}

# Show warning message with consistent format
# Usage: show_warning "Message text"
show_warning() {
    echo "⚠️  $1. Run: dotfiles update"
}