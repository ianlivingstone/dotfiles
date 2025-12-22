#!/usr/bin/env zsh
# Utility functions and status reporting
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Source shared utilities
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")" && pwd)"
source "$SHELL_DIR/utils.sh"

# Generic stow-based status checker
check_package_status() {
    local entry="$1"
    local dotfiles_dir="$2"
    
    # Parse package:target format (same logic as dotfiles.sh)
    local package target
    if [[ "$entry" == *":"* ]]; then
        package="${entry%:*}"
        target="${entry#*:}"
        # Safe variable expansion in target path
        target="${target/#\~/$HOME}"
        target="${target//\$HOME/$HOME}"
        target="${target//\$XDG_CONFIG_DIR/$XDG_CONFIG_DIR}"
    else
        package="$entry"
        target="$HOME"
    fi
    
    # Skip if package directory doesn't exist
    if [[ ! -d "$dotfiles_dir/$package" ]]; then
        echo "   ❌ $package → package directory not found"
        return 1
    fi
    
    # Use stow to check if package is properly stowed
    local stow_output exit_code
    cd "$dotfiles_dir" || return 1
    stow_output=$(stow --no --verbose --restow --target="$target" "$package" 2>&1)
    exit_code=$?
    
    # Determine status based on stow output and exit code
    if [[ $exit_code -eq 0 ]]; then
        if [[ -z "$stow_output" ]]; then
            # No output means already properly stowed
            echo "   ✅ $package → properly stowed to $target"
        elif [[ "$stow_output" =~ "reverts previous action" ]]; then
            # "reverts previous action" means stow is fixing/updating existing links
            echo "   ✅ $package → properly stowed to $target"
        else
            # Other changes needed
            local first_line=$(echo "$stow_output" | grep -E "^(LINK|UNLINK|MKDIR)" | head -1)
            echo "   ⚠️  $package → would make changes: $first_line"
        fi
    else
        local error_summary=$(echo "$stow_output" | head -1 | sed 's/stow: //')
        echo "   ❌ $package → error: $error_summary"
    fi
}

# Comprehensive unified dotfiles status
dotfiles_status() {
    echo "🏠 Dotfiles Status"
    echo "=================="
    echo
    
    # System Information
    echo "💻 System Information:"
    echo "   🖥️ Machine: $(whoami)@$(hostname -s)"
    echo "   🌐 Hostname: $(hostname)"
    echo "   📂 Dotfiles: $HOME/code/src/github.com/ianlivingstone/dotfiles"
    echo "   🐚 Shell: $SHELL ($ZSH_VERSION)"
    echo
    
    # Installation Status
    echo "📁 Installation Status:"
    
    # Load packages from config file and check each one using stow
    local dotfiles_dir="$HOME/code/src/github.com/ianlivingstone/dotfiles"
    local xdg_config_dir="$(get_xdg_config_dir)"
    
    # Set XDG_CONFIG_DIR for use in package config expansion
    export XDG_CONFIG_DIR="$xdg_config_dir"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        # Check this package using stow
        check_package_status "$line" "$dotfiles_dir"
    done < "$dotfiles_dir/packages.config"
    echo
    
    # Development Environment
    echo "🛠️  Development Environment:"
    
    # Package Managers
    if command -v brew &>/dev/null; then
        echo "   ✅ Homebrew: $(brew --version | head -1 | sed 's/Homebrew //')"
    else
        echo "   ❌ Homebrew: Not installed"
    fi
    
    if command -v stow &>/dev/null; then
        echo "   ✅ GNU Stow: $(stow --version | head -1 | sed 's/stow (GNU Stow) //')"
    else
        echo "   ❌ GNU Stow: Not installed"
    fi

    if command -v just &>/dev/null; then
        echo "   ✅ just: $(just --version 2>/dev/null | awk '{print $2}')"
    else
        echo "   ❌ just: Not installed"
    fi

    if command -v duckdb &>/dev/null; then
        echo "   ✅ duckdb: $(duckdb --version 2>/dev/null | awk '{print $1}')"
    else
        echo "   ❌ duckdb: Not installed"
    fi

    # Programming Languages
    # Check if NVM is available - load it first if installed
    local nvm_loaded=false
    if command -v nvm &>/dev/null; then
        nvm_loaded=true
    elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        # Load NVM to check its status
        export NVM_DIR="$HOME/.nvm"
        source "$NVM_DIR/nvm.sh" &>/dev/null
        nvm_loaded=true
    fi
    
    if [[ "$nvm_loaded" == "true" ]]; then
        local node_version=$(node --version 2>/dev/null || echo "none")
        local nvm_version=$(nvm --version 2>/dev/null || echo "unknown")
        local default_version=$(cat "$NVM_DIR/alias/default" 2>/dev/null || echo "none")
        echo "   ✅ Node.js: $node_version (via NVM $nvm_version)"
        echo "       └── Default: $default_version"
    else
        echo "   ❌ NVM: Not installed"
    fi
    
    # Check if GVM is available (should be loaded by languages.sh module)
    if command -v gvm &>/dev/null && [[ -n "$GVM_ROOT" ]]; then
        local go_version=$(go version 2>/dev/null | awk '{print $3}' || echo "none")
        local gvm_version=$(gvm version 2>/dev/null | head -1 || echo "unknown")
        local default_version=$(grep "gvm_go_name" "$GVM_ROOT/environments/default" 2>/dev/null | cut -d'"' -f2 || echo "none")
        echo "   ✅ Go: $go_version (via GVM $gvm_version)"
        echo "       └── Default: $default_version"
    elif command -v go &>/dev/null; then
        local go_version=$(go version 2>/dev/null | awk '{print $3}')
        echo "   ✅ Go: $go_version (system)"
    else
        echo "   ❌ Go: Not available"
    fi
    
    if command -v cargo &>/dev/null; then
        local rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
        echo "   ✅ Rust: $rust_version"
    else
        echo "   ❌ Rust: Not available"
    fi

    # Python & uv
    if command -v uv &>/dev/null; then
        local uv_version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        echo "   ✅ uv: $uv_version"

        # Check active Python and its source
        if command -v python3 &>/dev/null; then
            local python_version=$(python3 --version 2>/dev/null | awk '{print $2}')
            local python_path=$(which python3 2>/dev/null)
            local uv_pythons=$(uv python list 2>/dev/null | grep -c "cpython-" || echo "0")

            # Get required Python version from versions.config
            local required_python=$(get_version_requirement "python" 2>/dev/null || echo "3.11")

            # Determine Python source
            local python_source="system"
            if [[ "$python_path" == *"/.local/share/uv/python/"* ]]; then
                python_source="uv-managed"
            fi

            # Check if version meets requirement
            local major_version=${python_version%%.*}
            local minor_version=${python_version#*.}
            minor_version=${minor_version%%.*}
            local required_minor=${required_python#*.}
            required_minor=${required_minor%%.*}

            local version_ok=true
            if [[ $major_version -lt 3 ]] || [[ $major_version -eq 3 && $minor_version -lt $required_minor ]]; then
                version_ok=false
            fi

            # Display status with appropriate icon and message
            if [[ "$version_ok" == "true" ]]; then
                echo "   ✅ Python: $python_version ($python_source)"
            else
                echo "   ⚠️  Python: $python_version ($python_source) - requires $required_python+"
            fi

            # Show path for clarity
            echo "       └── Active: $python_path"

            # Show uv-managed versions if available
            if [[ $uv_pythons -gt 0 ]]; then
                echo "       └── uv-managed: $(uv python list 2>/dev/null | grep 'cpython-' | awk '{print $1}' | paste -sd ',' - || echo 'none')"
            fi
        else
            local uv_pythons=$(uv python list 2>/dev/null | grep -c "cpython-" || echo "0")
            if [[ $uv_pythons -gt 0 ]]; then
                echo "   ⚠️  Python: Not in PATH ($uv_pythons uv-managed versions available)"
                echo "       └── uv-managed: $(uv python list 2>/dev/null | grep 'cpython-' | awk '{print $1}' | paste -sd ',' - || echo 'none')"
            else
                echo "   ❌ Python: Not available"
            fi
        fi
    else
        echo "   ❌ uv: Not installed"
        if command -v python3 &>/dev/null; then
            local python_version=$(python3 --version 2>/dev/null | awk '{print $2}')
            local required_python=$(get_version_requirement "python" 2>/dev/null || echo "3.11")

            # Check version requirement
            local major_version=${python_version%%.*}
            local minor_version=${python_version#*.}
            minor_version=${minor_version%%.*}
            local required_minor=${required_python#*.}
            required_minor=${required_minor%%.*}

            if [[ $major_version -lt 3 ]] || [[ $major_version -eq 3 && $minor_version -lt $required_minor ]]; then
                echo "   ⚠️  Python: $python_version (system) - requires $required_python+"
            else
                echo "   ✅ Python: $python_version (system)"
            fi
        else
            echo "   ❌ Python: Not available"
        fi
    fi

    # Editor and Tools
    if command -v nvim &>/dev/null; then
        echo "   ✅ Neovim: $(nvim --version | head -1 | awk '{print $2}')"
    else
        echo "   ❌ Neovim: Not installed"
    fi
    
    if command -v tmux &>/dev/null; then
        echo "   ✅ Tmux: $(tmux -V | awk '{print $2}')"
    else
        echo "   ❌ Tmux: Not installed"
    fi
    
    if command -v starship &>/dev/null; then
        echo "   ✅ Starship: $(starship --version | head -1 | awk '{print $2}')"
    else
        echo "   ❌ Starship: Not installed"
    fi
    
    # Docker
    if command -v docker &>/dev/null; then
        local docker_client_version=$(docker --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        if [[ -n "$docker_client_version" ]]; then
            local major_version=${docker_client_version%%.*}
            if [[ $major_version -ge 28 ]]; then
                # Check if Docker daemon is running and get server version
                local docker_server_info=$(docker info --format '{{.ServerVersion}}' 2>/dev/null)
                if [[ -n "$docker_server_info" ]]; then
                    local server_major=${docker_server_info%%.*}
                    if [[ $server_major -ge 28 ]]; then
                        echo "   ✅ Docker: Client $docker_client_version, Server $docker_server_info"
                    else
                        echo "   ⚠️  Docker: Client $docker_client_version, Server $docker_server_info (server <28)"
                    fi
                else
                    echo "   ⚠️  Docker: Client $docker_client_version (daemon not running)"
                fi
            else
                echo "   ⚠️  Docker: $docker_client_version (requires 28+)"
            fi
        else
            echo "   ❌ Docker: Version detection failed"
        fi
    else
        echo "   ❌ Docker: Not installed"
    fi
    echo
    
    # Security & Agents
    echo "🔐 Security & Agents:"
    local xdg_config="$(get_xdg_config_dir)"
    
    # SSH Keys Summary
    if [[ -f "$xdg_config/ssh/machine.config" ]]; then
        local ssh_key_count=$(grep -c "IdentityFile" "$xdg_config/ssh/machine.config" 2>/dev/null | tr -d '\n' || echo "0")
        local encrypted_count=0
        
        while IFS= read -r line; do
            local key_path=$(echo "$line" | awk '{print $2}' | sed "s|~|$HOME|")
            if [[ -f "$key_path" ]] && ! ssh-keygen -y -P "" -f "$key_path" &>/dev/null; then
                encrypted_count=$((encrypted_count + 1))
            fi
        done < <(grep "IdentityFile" "$xdg_config/ssh/machine.config" 2>/dev/null)
        
        if [[ $ssh_key_count -eq $encrypted_count ]] && [[ $ssh_key_count -gt 0 ]]; then
            echo "   🎯 SSH Keys: $ssh_key_count configured, all encrypted"
        elif [[ $ssh_key_count -gt 0 ]]; then
            echo "   ⚠️  SSH Keys: $ssh_key_count configured, $encrypted_count encrypted"
        else
            echo "   ❌ SSH Keys: None configured"
        fi
    else
        echo "   ❌ SSH Keys: No configuration found"
    fi
    
    # GPG Key Summary
    if command -v gpg &> /dev/null; then
        # Get the default key directly from GPG
        local selected_key=$(gpg --list-secret-keys --with-colons 2>/dev/null | grep "^sec:" | head -1 | cut -d: -f5)
        
        # If no secret keys, try to get default key from config as fallback
        if [[ -z "$selected_key" ]]; then
            if [[ -f "$xdg_config/gpg/machine.config" ]]; then
                selected_key=$(grep "^default-key" "$xdg_config/gpg/machine.config" 2>/dev/null | awk '{print $2}')
            elif [[ -f "$HOME/.gnupg/gpg.conf" ]]; then
                selected_key=$(grep "^default-key" "$HOME/.gnupg/gpg.conf" 2>/dev/null | awk '{print $2}')
            fi
        fi
        
        if [[ -n "$selected_key" ]]; then
            if pgrep -x "gpg-agent" >/dev/null && gpg-connect-agent --quiet /bye &>/dev/null; then
                echo "   🎯 GPG Key: $selected_key (encrypted, agent running)"
            else
                echo "   🎯 GPG Key: $selected_key (encrypted)"
            fi
        else
            echo "   ❌ GPG Key: None selected"
        fi
    else
        echo "   ❌ GPG: Not available"
    fi
    
    # Agent Status
    if [[ -n "$SSH_AUTH_SOCK" ]] && ssh-add -l &>/dev/null; then
        local key_count=$(ssh-add -l 2>/dev/null | wc -l | xargs)
        echo "   ✅ SSH Agent: Running ($key_count keys loaded)"
        
        # Show loaded SSH keys
        ssh-add -l 2>/dev/null | while read -r line; do
            local key_size=$(echo "$line" | awk '{print $1}')
            local key_hash=$(echo "$line" | awk '{print $2}')
            local key_comment=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^ *//')
            local key_name=$(basename "$key_comment" 2>/dev/null || echo "$key_comment")
            echo "       └── $key_name (${key_size}-bit)"
        done
    else
        echo "   ❌ SSH Agent: Not running"
    fi
    
    if pgrep -x "gpg-agent" > /dev/null && gpg-connect-agent --quiet /bye &>/dev/null; then
        echo "   ✅ GPG Agent: Running"
        
        # Show active GPG key from machine config
        if [[ -n "$selected_key" ]]; then
            local key_info=$(gpg --list-keys --keyid-format=short "$selected_key" 2>/dev/null | grep "^uid" | head -1 | sed 's/uid.*] //')
            if [[ -n "$key_info" ]]; then
                echo "       └── Using: $selected_key ($key_info)"
            else
                echo "       └── Using: $selected_key"
            fi
        fi
    else
        echo "   ❌ GPG Agent: Not running"
    fi
    
    # Connectivity
    if ssh -T git@github.com -o ConnectTimeout=5 -o BatchMode=yes 2>&1 | grep -q "successfully authenticated"; then
        echo "   ✅ GitHub SSH: Connected"
    else
        echo "   ❌ GitHub SSH: Connection failed"
    fi
    
    # Security permissions validation
    validate_security_permissions
    
    # Version requirements validation
    echo
    echo "📋 Version Requirements:"
    validate_tool_versions
    
    echo
    echo "💡 Run './dotfiles.sh help' for management commands"
}

# Security validation and auto-fix function
# Usage: validate_security_permissions [--fix] [--quiet] [--startup]
validate_security_permissions() {
    local auto_fix=false
    local quiet=false  
    local startup_mode=false
    local show_header=true
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix) auto_fix=true; shift ;;
            --quiet) quiet=true; show_header=false; shift ;;
            --startup) startup_mode=true; quiet=true; show_header=false; shift ;;
            *) shift ;;
        esac
    done
    
    local security_issues=()
    local fixed_issues=()
    local xdg_config="$(get_xdg_config_dir)"
    
    [[ "$show_header" == "true" ]] && echo "" && echo "🔒 Security Permissions:"
    
    # Define files that should be 600 (user read/write only)
    local secure_files=(
        "$xdg_config/git/machine.config"
        "$xdg_config/ssh/machine.config" 
        "$HOME/.gnupg/gpg.conf"
        "$HOME/.gnupg/gpg-agent.conf"
        "$HOME/.ssh/id_ed25519"
        "$HOME/.ssh/id_rsa"
    )
    
    # Define directories that should be 700 (user access only)
    local secure_dirs=(
        "$HOME/.gnupg"
        "$HOME/.ssh"
        "$xdg_config/ssh"
        "$xdg_config/git" 
        "$xdg_config/gpg"
    )
    
    # Check and optionally fix file permissions
    for file in "${secure_files[@]}"; do
        if [[ -f "$file" ]]; then
            local perms=$(stat -f %A "$file" 2>/dev/null || stat -c %a "$file" 2>/dev/null || echo "unknown")
            if [[ "$perms" != "600" ]]; then
                if [[ "$auto_fix" == "true" ]]; then
                    if chmod 600 "$file" 2>/dev/null; then
                        fixed_issues+=("$file ($perms → 600)")
                    else
                        security_issues+=("File $file has permissions $perms (should be 600)")
                    fi
                else
                    security_issues+=("File $file has permissions $perms (should be 600)")
                fi
            fi
        fi
    done
    
    # Check and optionally fix directory permissions
    for dir in "${secure_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local perms=$(stat -f %A "$dir" 2>/dev/null || stat -c %a "$dir" 2>/dev/null || echo "unknown")
            if [[ "$perms" != "700" ]] && [[ "$perms" != "755" ]]; then
                if [[ "$auto_fix" == "true" ]]; then
                    if chmod 700 "$dir" 2>/dev/null; then
                        fixed_issues+=("$dir ($perms → 700)")
                    else
                        security_issues+=("Directory $dir has permissions $perms (should be 700)")
                    fi
                else
                    security_issues+=("Directory $dir has permissions $perms (should be 700)")
                fi
            fi
        fi
    done
    
    # Check and optionally fix SSH key permissions specifically
    for key in ~/.ssh/id_*; do
        if [[ -f "$key" ]] && [[ "$key" != *.pub ]]; then
            local perms=$(stat -f %A "$key" 2>/dev/null || stat -c %a "$key" 2>/dev/null || echo "unknown")
            if [[ "$perms" != "600" ]]; then
                if [[ "$auto_fix" == "true" ]]; then
                    if chmod 600 "$key" 2>/dev/null; then
                        fixed_issues+=("$key ($perms → 600)")
                    else
                        security_issues+=("SSH private key $key has permissions $perms (should be 600)")
                    fi
                else
                    security_issues+=("SSH private key $key has permissions $perms (should be 600)")
                fi
            fi
        fi
    done
    
    # Check and fix only managed ~/.config subdirectories to be user-only accessible
    local managed_config_dirs=("$HOME/.config/git" "$HOME/.config/ssh" "$HOME/.config/gpg" "$HOME/.config/nvim")
    for config_dir in "${managed_config_dirs[@]}"; do
        if [[ -d "$config_dir" ]]; then
            local perms=$(stat -f %A "$config_dir" 2>/dev/null || stat -c %a "$config_dir" 2>/dev/null || echo "unknown")
            if [[ "$perms" != "700" ]]; then
                if [[ "$auto_fix" == "true" ]]; then
                    if chmod 700 "$config_dir" 2>/dev/null; then
                        fixed_issues+=("$config_dir ($perms → 700)")
                    else
                        security_issues+=("Directory $config_dir has permissions $perms (should be 700)")
                    fi
                else
                    security_issues+=("Directory $config_dir has permissions $perms (should be 700)")
                fi
            fi
        fi
    done
    
    # Output results based on mode
    if [[ "$quiet" == "false" ]]; then
        if [[ ${#fixed_issues[@]} -gt 0 ]]; then
            echo "   ✅ Fixed ${#fixed_issues[@]} permission issues"
            if [[ "$auto_fix" == "false" ]]; then
                for issue in "${fixed_issues[@]}"; do
                    echo "       • Fixed: $issue"
                done
            fi
        fi
        
        if [[ ${#security_issues[@]} -eq 0 ]] && [[ ${#fixed_issues[@]} -eq 0 ]]; then
            echo "   ✅ All security-sensitive files have proper permissions"
        elif [[ ${#security_issues[@]} -gt 0 ]]; then
            echo "   ⚠️  Security permission issues found:"
            for issue in "${security_issues[@]}"; do
                echo "       • $issue"
            done
            echo ""
            echo "   💡 Fix with: fix_security_permissions or manually: chmod 600 <files> && chmod 700 <dirs>"
        fi
    elif [[ "$startup_mode" == "true" ]]; then
        # Show critical security warnings on startup (but don't auto-fix)
        if [[ ${#security_issues[@]} -gt 0 ]]; then
            echo "⚠️  SECURITY WARNING: Found ${#security_issues[@]} permission issue(s) that need attention!"
            echo "   Run 'fix_security_permissions' to fix, or 'dotfiles status' for details"
        fi
    fi
}

# Fix security permissions automatically (wrapper for unified function)
fix_security_permissions() {
    echo "🔒 Fixing security permissions..."
    validate_security_permissions --fix
}

# Quick security check that runs on shell startup  
# Warns about critical security issues but does NOT fix them automatically
quick_security_check() {
    validate_security_permissions --startup
}

# Version validation function
validate_tool_versions() {
    local versions_file="$HOME/code/src/github.com/ianlivingstone/dotfiles/versions.config"
    local issues=()
    
    if [[ ! -f "$versions_file" ]]; then
        return 0
    fi
    
    while IFS=':' read -r tool min_version; do
        # Skip comments and empty lines
        [[ -z "$tool" || "$tool" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        tool=$(echo "$tool" | xargs)
        min_version=$(echo "$min_version" | xargs)
        
        if command -v "$tool" &>/dev/null; then
            local current_version=""
            case "$tool" in
                "docker")
                    current_version=$(docker --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "git")
                    current_version=$(git --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "node")
                    current_version=$(node --version 2>/dev/null)
                    ;;
                "go")
                    current_version=$(go version 2>/dev/null | grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+')
                    ;;
                "zsh")
                    current_version=$(zsh --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "stow")
                    current_version=$(stow --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "brew")
                    current_version=$(brew --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "just")
                    current_version=$(just --version 2>/dev/null | awk '{print $2}' | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "duckdb")
                    current_version=$(duckdb --version 2>/dev/null | awk '{print $1}' | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "nvim")
                    current_version=$(nvim --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "tmux")
                    current_version=$(tmux -V 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+')
                    ;;
                "starship")
                    current_version=$(starship --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "jq")
                    current_version=$(jq --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+')
                    ;;
                "rg")
                    current_version=$(rg --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "luarocks")
                    current_version=$(luarocks --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "gpg")
                    current_version=$(gpg --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "nvm")
                    current_version=$(nvm --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "gvm")
                    current_version=$(gvm version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "rustup")
                    current_version=$(rustup --version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "uv")
                    current_version=$(uv --version 2>/dev/null | awk '{print $2}' | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
                    ;;
                "python")
                    # Check python3 version
                    if command -v python3 &>/dev/null; then
                        current_version=$(python3 --version 2>/dev/null | awk '{print $2}' | grep -o '[0-9]\+\.[0-9]\+' | head -1)
                    fi
                    ;;
            esac
            
            if [[ -n "$current_version" ]]; then
                # Normalize versions for comparison (remove prefixes for comparison only)
                local current_clean="$current_version"
                local min_clean="$min_version"
                
                # Remove common prefixes for comparison
                current_clean="${current_clean#v}"
                current_clean="${current_clean#go}"
                min_clean="${min_clean#v}"
                min_clean="${min_clean#go}"
                
                # Simple version comparison (works for major.minor.patch)
                if ! printf '%s\n%s\n' "$min_clean" "$current_clean" | sort -V | head -1 | grep -q "^$min_clean$"; then
                    issues+=("$tool: $current_version < $min_version (required)")
                fi
            fi
        fi
    done < "$versions_file"
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "   ⚠️  Version issues found:"
        for issue in "${issues[@]}"; do
            echo "       • $issue"
        done
        return 1
    else
        echo "   ✅ All tools meet minimum version requirements"
        return 0
    fi
}

# Simple alias to dotfiles.sh script (now handles caching internally)
alias dotfiles="$HOME/code/src/github.com/ianlivingstone/dotfiles/dotfiles.sh"

# Legacy aliases for backward compatibility
security_status() {
    dotfiles_status
}

agents_status() {
    dotfiles_status
}