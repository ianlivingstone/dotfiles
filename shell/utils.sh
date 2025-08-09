# Shared utility functions for dotfiles shell modules

# Get XDG config directory with consistent fallback
# Usage: get_xdg_config_dir
get_xdg_config_dir() {
    echo "${XDG_CONFIG_HOME:-$HOME/.config}"
}

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

# Install global npm packages from package.json
# Usage: install_npm_globals package_json_file
install_npm_globals() {
    local package_json="$1"
    
    if [[ ! -f "$package_json" ]]; then
        echo "⚠️  Global packages config not found: $package_json"
        return 1
    fi
    
    echo "📦 Installing global npm packages from $(basename "$package_json")..."
    
    # Use npm to install all dependencies globally
    # Create a temp directory and copy the package.json there
    local temp_dir=$(mktemp -d)
    chmod 700 "$temp_dir"
    trap "rm -rf '$temp_dir'" EXIT INT TERM
    cp "$package_json" "$temp_dir/package.json"
    
    # Change to temp directory and install all dependencies globally
    (
        cd "$temp_dir"
        # Extract package names and install them globally
        if command -v jq &>/dev/null; then
            local packages=$(jq -r '.dependencies | keys[]' package.json 2>/dev/null | tr '\n' ' ')
        else
            # Fallback parsing
            local packages=$(grep -A 20 '"dependencies"' package.json | grep -o '"[^"]*"' | grep -v "dependencies\|latest" | tr -d '"' | tr '\n' ' ')
        fi
        
        if [[ -n "$packages" ]]; then
            # Check which packages need installation/update
            local packages_to_install=()
            
            for package in $packages; do
                if ! npm list -g "$package" >/dev/null 2>&1; then
                    packages_to_install+=("$package")
                fi
            done
            
            if [[ ${#packages_to_install[@]} -gt 0 ]]; then
                echo "  → Installing missing packages: ${packages_to_install[*]}"
                npm install -g "${packages_to_install[@]}"
            else
                echo "  → All global packages already installed"
            fi
        else
            echo "⚠️  No packages found in dependencies"
        fi
    )
    
    # Clean up temp directory
    rm -rf "$temp_dir"
}