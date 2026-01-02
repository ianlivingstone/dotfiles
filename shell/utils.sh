#!/usr/bin/env zsh
# Shared utility functions for dotfiles shell modules
# SOURCED MODULE: Uses graceful error handling, never use set -e


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

# Function to read version from versions.config
get_version_requirement() {
    local tool="$1"
    local versions_file="$HOME/code/src/github.com/ianlivingstone/dotfiles/versions.config"
    
    if [[ ! -f "$versions_file" ]]; then
        return 1
    fi
    
    # Look for the tool in versions.config
    local version=$(grep "^${tool}:" "$versions_file" 2>/dev/null | cut -d':' -f2 | xargs)
    
    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi
    
    return 1
}

# Install global npm packages from package.json
# Usage: install_npm_globals package_json_file
install_npm_globals() {
    # Temporarily disable strict mode for this function (using local scope)
    local saved_errexit="" saved_nounset="" saved_pipefail=""
    [[ $- == *e* ]] && saved_errexit="e"
    [[ $- == *u* ]] && saved_nounset="u"
    [[ $- == *o* ]] && saved_pipefail="o pipefail"
    set +euo pipefail
    trap - ERR

    local package_json="$1"

    if [[ ! -f "$package_json" ]]; then
        echo "⚠️  Global packages config not found: $package_json"
        return 1
    fi

    echo "📦 Installing/updating global npm packages from $(basename "$package_json")..."

    if ! command -v jq &>/dev/null; then
        echo "⚠️  jq not found. Installing jq is recommended for reliable package management."
        echo "   Install with: brew install jq"
        return 1
    fi

    # Extract package@version pairs from package.json
    local packages_to_install=()
    while IFS='@' read -r package version; do
        if [[ -n "$package" ]] && [[ -n "$version" ]]; then
            # Get currently installed version (if any)
            local installed_version=""
            if npm list -g "$package" >/dev/null 2>&1; then
                installed_version=$(npm list -g "$package" --depth=0 2>/dev/null | grep "$package@" | sed 's/.*@//' | head -1)
            fi

            # Check if we need to install/update
            if [[ -z "$installed_version" ]]; then
                echo "  → $package: not installed, will install $version"
                packages_to_install+=("$package@$version")
            elif [[ "$installed_version" != "$version" ]]; then
                echo "  → $package: $installed_version → $version (updating)"
                packages_to_install+=("$package@$version")
            else
                echo "  ✓ $package@$version (already up to date)"
            fi
        fi
    done < <(jq -r '.dependencies | to_entries[] | "\(.key)@\(.value)"' "$package_json" 2>/dev/null)

    # Install/update packages if needed
    if [[ ${#packages_to_install[@]} -gt 0 ]]; then
        echo ""
        echo "Installing/updating ${#packages_to_install[@]} package(s)..."
        npm install -g "${packages_to_install[@]}"
        echo ""
        echo "✅ Global packages updated successfully!"
    else
        echo ""
        echo "✅ All global packages are already up to date!"
    fi

    # Restore original shell options
    [[ -n "$saved_errexit" ]] && set -e
    [[ -n "$saved_nounset" ]] && set -u
    [[ -n "$saved_pipefail" ]] && set -o pipefail
    trap 'echo "❌ Installation failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
}

# Check if system is a macOS laptop (has battery)
# Usage: is_macos_laptop
is_macos_laptop() {
    # Check if we're on macOS
    [[ "$(uname -s)" != "Darwin" ]] && return 1
    
    # Check if system has battery using pmset
    local battery_info
    battery_info=$(pmset -g batt 2>/dev/null) || return 1
    
    # Look for "InternalBattery" or "Battery" in output
    [[ "$battery_info" =~ (InternalBattery|Battery) ]] && return 0
    
    return 1
}

# Get battery status with caching (30 second cache)
# Usage: get_battery_status
get_battery_status() {
    # Only run on macOS laptops
    is_macos_laptop || return 1
    
    # Cache variables
    local cache_file="$HOME/.cache/dotfiles_battery_cache"
    local cache_duration=30
    
    # Create cache directory if it doesn't exist
    mkdir -p "$(dirname "$cache_file")"
    
    # Check if cache is valid (less than 30 seconds old)
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [[ $cache_age -lt $cache_duration ]]; then
            cat "$cache_file"
            return 0
        fi
    fi
    
    # Get fresh battery info
    local battery_info
    battery_info=$(pmset -g batt 2>/dev/null) || return 1
    
    # Parse battery percentage and status
    local percentage
    local battery_status
    local time_remaining
    
    # Extract percentage
    if [[ "$battery_info" =~ ([0-9]+)% ]]; then
        percentage="${match[1]}"
    else
        return 1
    fi
    
    # Extract status
    if [[ "$battery_info" =~ (charging|discharging|charged|AC\ attached) ]]; then
        battery_status="${match[1]}"
    else
        battery_status="unknown"
    fi
    
    # Extract time remaining (optional)
    time_remaining=""
    if [[ "$battery_info" =~ ([0-9]+:[0-9]+)\ remaining ]]; then
        time_remaining="${match[1]}"
    fi
    
    # Format output with appropriate emoji
    local battery_display
    if [[ "$battery_status" =~ ^(charging|AC\ attached)$ ]]; then
        battery_display="⚡ ${percentage}%"
    elif [[ $percentage -le 15 ]]; then
        battery_display="🪫 ${percentage}%"
    elif [[ $percentage -le 30 ]]; then
        battery_display="🔋 ${percentage}%"
    else
        battery_display="🔋 ${percentage}%"
    fi
    
    # Add time remaining if available and not "0:00"
    if [[ -n "$time_remaining" && "$time_remaining" != "0:00" ]]; then
        battery_display="${battery_display} (${time_remaining})"
    fi
    
    # Cache the result
    echo "$battery_display" > "$cache_file"
    echo "$battery_display"
}

# Detect if SSH key is encrypted without triggering password prompt
# Usage: is_ssh_key_encrypted /path/to/key
is_ssh_key_encrypted() {
    local key_path="$1"
    
    [[ ! -f "$key_path" ]] && return 1
    [[ "$key_path" == *.pub ]] && return 1  # Skip public keys
    
    # Check if key file contains encryption headers
    if grep -q "ENCRYPTED\|Proc-Type.*ENCRYPTED" "$key_path" 2>/dev/null; then
        return 0  # Encrypted
    fi
    
    # For OpenSSH format, check if it contains bcrypt/aes markers
    if grep -q "openssh-key-v1" "$key_path" 2>/dev/null; then
        # Try to detect encryption by looking for key material patterns
        # Non-encrypted OpenSSH keys have predictable patterns
        if [[ $(wc -l < "$key_path") -gt 10 ]] && grep -q "bcrypt\|aes" "$key_path" 2>/dev/null; then
            return 0  # Likely encrypted
        fi
    fi
    
    return 1  # Not encrypted
}

# Check if SSH key is already loaded in SSH agent
# Usage: is_ssh_key_loaded /path/to/key
is_ssh_key_loaded() {
    local key_path="$1"
    
    # Check if SSH agent is running
    [[ -z "$SSH_AUTH_SOCK" ]] && return 1
    
    # Get public key fingerprint
    local fingerprint
    fingerprint=$(ssh-keygen -lf "$key_path" 2>/dev/null | awk '{print $2}') || return 1
    
    # Check if fingerprint is in loaded keys
    ssh-add -l 2>/dev/null | grep -q "$fingerprint"
}

# Add SSH key to macOS Keychain (one-time setup)
# Usage: add_ssh_key_to_keychain /path/to/key
add_ssh_key_to_keychain() {
    local key_path="$1"
    
    [[ ! -f "$key_path" ]] && return 1
    [[ "$key_path" == *.pub ]] && return 1  # Skip public keys
    
    # Only add if key is encrypted
    if ! is_ssh_key_encrypted "$key_path"; then
        echo "⚠️  Key $key_path is not encrypted, skipping keychain integration"
        return 1
    fi
    
    echo "🔐 Adding SSH key to macOS Keychain: $(basename "$key_path")"
    echo "💡 You'll be prompted for your SSH key passphrase once to save it to Keychain"
    
    # Add to agent and keychain
    if ssh-add --apple-use-keychain "$key_path"; then
        echo "✅ SSH key added to Keychain successfully"
        return 0
    else
        echo "❌ Failed to add SSH key to Keychain"
        return 1
    fi
}

# Remove SSH key from macOS Keychain
# Usage: remove_ssh_key_from_keychain /path/to/key  
remove_ssh_key_from_keychain() {
    local key_path="$1"
    
    [[ ! -f "$key_path" ]] && return 1
    [[ "$key_path" == *.pub ]] && return 1  # Skip public keys
    
    echo "🗑️  Removing SSH key from Keychain: $(basename "$key_path")"
    
    # Remove from agent (also removes from keychain)
    if ssh-add -d "$key_path" 2>/dev/null; then
        echo "✅ SSH key removed from Keychain successfully"
        return 0
    else
        echo "⚠️  SSH key may not have been in agent/keychain"
        return 0  # Not necessarily an error
    fi
}

# Lazy load SSH key (checks if needed, loads from keychain if available)
# Usage: lazy_load_ssh_key /path/to/key [--quiet]
lazy_load_ssh_key() {
    local key_path="$1"
    local quiet="${2:-}"

    [[ ! -f "$key_path" ]] && return 1
    [[ "$key_path" == *.pub ]] && return 1  # Skip public keys

    # Skip if already loaded
    if is_ssh_key_loaded "$key_path"; then
        return 0
    fi

    # If key is encrypted, try loading from keychain
    if is_ssh_key_encrypted "$key_path"; then
        # Try to load from keychain silently (no password prompt)
        # The --apple-load-keychain flag loads ALL keys from keychain without prompting
        if ssh-add --apple-load-keychain 2>/dev/null; then
            # Check if our key is now loaded
            if is_ssh_key_loaded "$key_path"; then
                return 0
            fi
        fi

        # Key not in keychain - only show message if not quiet mode
        # During shell startup, we run in quiet mode to avoid cluttering output
        if [[ "$quiet" != "--quiet" ]]; then
            echo "💡 SSH key $(basename "$key_path") requires setup - run: ssh-add --apple-use-keychain $key_path"
        fi
        return 1
    else
        # Key is not encrypted, add directly (no password needed)
        if ssh-add "$key_path" 2>/dev/null; then
            return 0
        else
            echo "❌ Failed to load unencrypted SSH key: $(basename "$key_path")"
            return 1
        fi
    fi
}