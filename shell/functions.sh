# Utility functions

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
    local packages=("shell" "git" "ssh" "nvim" "tmux" "misc")
    
    for package in "${packages[@]}"; do
        case "$package" in
            "shell")
                if [[ -L ~/.zshrc ]]; then
                    echo "   ✅ shell → ~/.zshrc (linked)"
                elif [[ -f ~/.zshrc ]]; then
                    echo "   ❌ shell → ~/.zshrc (file exists, not linked)"
                else
                    echo "   ❌ shell → ~/.zshrc (not found)"
                fi
                ;;
            "git")
                if [[ -L ~/.gitconfig ]]; then
                    echo "   ✅ git → ~/.gitconfig (linked)"
                elif [[ -f ~/.gitconfig ]]; then
                    echo "   ❌ git → ~/.gitconfig (file exists, not linked)"
                else
                    echo "   ❌ git → ~/.gitconfig (not found)"
                fi
                ;;
            "ssh")
                if [[ -L ~/.ssh/config ]]; then
                    echo "   ✅ ssh → ~/.ssh/config (linked)"
                elif [[ -f ~/.ssh/config ]]; then
                    echo "   ❌ ssh → ~/.ssh/config (file exists, not linked)"
                else
                    echo "   ❌ ssh → ~/.ssh/config (not found)"
                fi
                ;;
            "nvim")
                if [[ -L ~/.config/nvim ]]; then
                    echo "   ✅ nvim → ~/.config/nvim/ (linked)"
                elif [[ -d ~/.config/nvim ]]; then
                    echo "   ❌ nvim → ~/.config/nvim/ (directory exists, not linked)"
                else
                    echo "   ❌ nvim → ~/.config/nvim/ (not found)"
                fi
                ;;
            "tmux")
                if [[ -L ~/.tmux.conf ]]; then
                    echo "   ✅ tmux → ~/.tmux.conf (linked)"
                elif [[ -f ~/.tmux.conf ]]; then
                    echo "   ❌ tmux → ~/.tmux.conf (file exists, not linked)"
                else
                    echo "   ❌ tmux → ~/.tmux.conf (not found)"
                fi
                ;;
            "misc")
                if [[ -L ~/.config/starship.toml ]]; then
                    echo "   ✅ starship → ~/.config/starship.toml (linked)"
                elif [[ -f ~/.config/starship.toml ]]; then
                    echo "   ❌ starship → ~/.config/starship.toml (file exists, not linked)"
                else
                    echo "   ❌ starship → ~/.config/starship.toml (not found)"
                fi
                ;;
        esac
    done
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
    # Check if NVM is available (should be loaded by languages.sh module)
    if command -v nvm &>/dev/null; then
        local node_version=$(node --version 2>/dev/null || echo "none")
        local nvm_version=$(nvm --version 2>/dev/null || echo "unknown")
        local default_version=$(cat "$NVM_DIR/alias/default" 2>/dev/null || echo "none")
        echo "   ✅ Node.js: $node_version (via NVM $nvm_version)"
        echo "       └── Default: $default_version"
    else
        echo "   ❌ NVM: Not loaded"
    fi
    
    if command -v go &>/dev/null; then
        local go_version=$(go version 2>/dev/null | awk '{print $3}')
        echo "   ✅ Go: $go_version"
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
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
    
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
        local selected_key=""
        if [[ -f "$xdg_config/gpg/machine.config" ]]; then
            selected_key=$(grep "^default-key" "$xdg_config/gpg/machine.config" 2>/dev/null | awk '{print $2}')
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

# Main dotfiles command - just calls the status function
dotfiles() {
    dotfiles_status
}

# Legacy aliases for backward compatibility
security_status() {
    dotfiles_status
}

agents_status() {
    dotfiles_status
}