# Utility functions

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
        # Expand variables in target path
        target=$(eval echo "$target")
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
    echo
    
    # Security & Agents
    echo "🔐 Security & Agents:"
    local xdg_config="$(get_xdg_config_dir)"
    
    # SSH Keys Summary
    if [[ -f "$xdg_config/ssh/machine.config" ]]; then
        local ssh_key_count=$(grep -c "IdentityFile" "$xdg_config/ssh/machine.config" 2>/dev/null || echo "0")
        local encrypted_count=0
        
        while IFS= read -r line; do
            local key_path=$(echo "$line" | awk '{print $2}' | sed "s|~|$HOME|")
            if [[ -f "$key_path" ]] && ! ssh-keygen -y -P "" -f "$key_path" &>/dev/null; then
                ((encrypted_count++))
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
    
    echo
    echo "💡 Run './dotfiles.sh help' for management commands"
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