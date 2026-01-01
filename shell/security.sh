#!/usr/bin/env zsh
# Security validation for SSH and GPG keys
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Source shared utilities
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")" && pwd)"
source "$SHELL_DIR/utils.sh"

validate_ssh_keys() {
    local xdg_config="$(get_xdg_config_dir)"
    if [[ ! -f "$xdg_config/ssh/machine.config" ]]; then
        return 0  # No SSH config to validate
    fi
    
    local has_unencrypted=false
    # Extract IdentityFile paths and validate them
    grep "IdentityFile" "$xdg_config/ssh/machine.config" | while read -r line; do
        local key_path=$(echo "$line" | awk '{print $2}' | sed "s|~|$HOME|")
        if [[ -f "$key_path" ]]; then
            local key_name=$(basename "$key_path")
            
            # Check if SSH key is encrypted (has passphrase)
            if ssh-keygen -y -P "" -f "$key_path" &>/dev/null; then
                echo "🚨 SECURITY ERROR: Unencrypted SSH key detected: $key_name"
                echo "🔒 Please encrypt your SSH key with: ssh-keygen -p -f $key_path"
                echo "❌ Cannot proceed with unencrypted keys"
                has_unencrypted=true
            fi
        fi
    done
    
    if [[ "$has_unencrypted" == "true" ]]; then
        return 1
    fi
    
    return 0
}

validate_gpg_keys() {
    # Check if gpg is available
    if ! command -v gpg &> /dev/null; then
        return 0  # Skip validation if GPG not available
    fi
    
    # Get the selected GPG key from machine config
    local xdg_config="$(get_xdg_config_dir)"
    local selected_key=""
    
    if [[ -f "$xdg_config/gpg/machine.config" ]]; then
        selected_key=$(grep "^default-key" "$xdg_config/gpg/machine.config" 2>/dev/null | awk '{print $2}')
    fi
    
    if [[ -z "$selected_key" ]]; then
        return 0  # No specific key selected, skip validation
    fi
    
    # Check if the selected key exists
    local key_info=$(gpg --list-secret-keys --with-colons "$selected_key" 2>/dev/null | grep "^sec:")
    
    if [[ -n "$key_info" ]]; then
        # If GPG agent is running, assume the key is encrypted
        # (Agent wouldn't be useful for unencrypted keys)
        if pgrep -x "gpg-agent" >/dev/null && gpg-connect-agent --quiet /bye &>/dev/null; then
            # Agent is running and responsive - assume key is encrypted
            return 0
        fi
        
        # Agent not running - do a quick non-interactive test
        # Try to sign with empty passphrase without starting agent
        if echo "test" | timeout 3 gpg --batch --yes --passphrase "" --local-user "$selected_key" --armor --detach-sign >/dev/null 2>&1; then
            echo "🚨 SECURITY ERROR: Unencrypted GPG key detected: $selected_key"
            echo "🔒 Please add a passphrase with: gpg --edit-key $selected_key"
            echo "❌ Cannot proceed with unencrypted keys"
            return 1
        fi
        # If signing failed, key is encrypted (good!)
    fi
    
    return 0
}

# Main security validation function with caching
validate_key_security() {
    # Check if key security already validated in this shell session
    if [[ "$DOTFILES_KEY_SECURITY_VALIDATED" == "1" ]]; then
        return 0
    fi
    
    if ! validate_ssh_keys; then
        return 1
    fi
    
    if ! validate_gpg_keys; then
        return 1
    fi
    
    # Cache successful key security validation for subshells
    export DOTFILES_KEY_SECURITY_VALIDATED=1
    return 0
}

# Check GPG signing status
gpg-status() {
    echo "🔐 GPG Signing Status"
    echo "===================="
    echo ""

    # Check if GPG is installed
    if ! command -v gpg &>/dev/null; then
        echo "❌ GPG is not installed"
        return 1
    fi

    echo "✅ GPG is installed: $(gpg --version | head -1)"
    echo ""

    # Check if GPG agent is running
    if pgrep -x "gpg-agent" >/dev/null; then
        echo "✅ GPG agent is running"

        # Check if agent is responsive
        if gpg-connect-agent --quiet /bye &>/dev/null; then
            echo "✅ GPG agent is responsive"
        else
            echo "⚠️  GPG agent is not responsive"
        fi
    else
        echo "❌ GPG agent is not running"
    fi
    echo ""

    # Check configured signing key
    local signing_key=$(git config --get user.signingkey 2>/dev/null)
    if [[ -n "$signing_key" ]]; then
        echo "🔑 Configured signing key: $signing_key"

        # Check if key exists
        if gpg --list-secret-keys "$signing_key" &>/dev/null; then
            echo "✅ Key exists in keyring"

            # Get key info
            local key_info=$(gpg --list-secret-keys --with-colons "$signing_key" 2>/dev/null | grep "^uid:" | head -1 | cut -d: -f10)
            if [[ -n "$key_info" ]]; then
                echo "   └── $key_info"
            fi
        else
            echo "❌ Key not found in keyring"
        fi
    else
        echo "⚠️  No signing key configured in git config"
    fi
    echo ""

    # Check commit.gpgsign config
    local gpg_sign=$(git config --get commit.gpgsign 2>/dev/null)
    if [[ "$gpg_sign" == "true" ]]; then
        echo "✅ GPG signing is enabled (commit.gpgsign = true)"
    else
        echo "⚠️  GPG signing is not enabled (commit.gpgsign = ${gpg_sign:-false})"
    fi
    echo ""

    # Test if passphrase is cached
    if [[ -n "$signing_key" ]]; then
        echo "🧪 Testing passphrase cache..."
        if echo "test" | gpg --sign --local-user "$signing_key" --batch --no-tty --pinentry-mode loopback -o /dev/null 2>/dev/null; then
            echo "✅ Passphrase is cached and ready"
        else
            echo "❌ Passphrase is not cached"
            echo "   Run 'gpg-unlock' to cache your passphrase"
        fi
    fi
}

# Cache GPG passphrase by prompting for it
gpg-unlock() {
    # Check if GPG is installed
    if ! command -v gpg &>/dev/null; then
        echo "❌ GPG is not installed"
        return 1
    fi

    # Get configured signing key
    local signing_key=$(git config --get user.signingkey 2>/dev/null)
    if [[ -z "$signing_key" ]]; then
        echo "❌ No signing key configured"
        echo "   Set one with: git config --global user.signingkey <KEY_ID>"
        return 1
    fi

    # Check if key exists
    if ! gpg --list-secret-keys "$signing_key" &>/dev/null; then
        echo "❌ Signing key $signing_key not found in keyring"
        return 1
    fi

    echo "🔐 Unlocking GPG key: $signing_key"
    echo ""

    # Prompt for passphrase by doing a test sign operation
    # This will cache the passphrase in gpg-agent
    if echo "test" | gpg --sign --local-user "$signing_key" --armor -o /dev/null; then
        echo ""
        echo "✅ GPG passphrase cached successfully"
        echo "   Your passphrase is now cached for commits"
        return 0
    else
        echo ""
        echo "❌ Failed to cache GPG passphrase"
        return 1
    fi
}

# Check SSH agent and key status
ssh-status() {
    echo "🔑 SSH Agent Status"
    echo "==================="
    echo ""

    # Check if SSH is available
    if ! command -v ssh &>/dev/null; then
        echo "❌ SSH is not installed"
        return 1
    fi

    echo "✅ SSH is installed: $(ssh -V 2>&1)"
    echo ""

    # Check if SSH agent is running
    if [[ -n "$SSH_AUTH_SOCK" ]] && [[ -S "$SSH_AUTH_SOCK" ]]; then
        echo "✅ SSH agent is running"
        echo "   └── Socket: $SSH_AUTH_SOCK"
    else
        echo "❌ SSH agent is not running or not accessible"
        echo "   Run 'eval \$(ssh-agent)' to start the agent"
        return 1
    fi
    echo ""

    # List loaded keys
    local loaded_keys=$(ssh-add -l 2>/dev/null)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        local key_count=$(echo "$loaded_keys" | wc -l | tr -d ' ')
        echo "🔓 Loaded keys: $key_count"
        echo "$loaded_keys" | while read -r line; do
            echo "   └── $line"
        done
    elif [[ $exit_code -eq 1 ]]; then
        echo "⚠️  No SSH keys loaded in agent"
        echo "   Run 'ssh-unlock' to load your keys"
    else
        echo "❌ Could not communicate with SSH agent"
        return 1
    fi
    echo ""

    # Check for configured SSH keys
    local xdg_config="$(get_xdg_config_dir)"
    if [[ -f "$xdg_config/ssh/machine.config" ]]; then
        echo "📋 Configured SSH keys (from machine.config):"
        grep "IdentityFile" "$xdg_config/ssh/machine.config" | while read -r line; do
            local key_path=$(echo "$line" | awk '{print $2}' | sed "s|~|$HOME|")
            local key_name=$(basename "$key_path")
            if [[ -f "$key_path" ]]; then
                echo "   ✅ $key_name"
            else
                echo "   ❌ $key_name (file not found)"
            fi
        done
    elif [[ -d ~/.ssh ]]; then
        echo "📋 Available SSH keys in ~/.ssh:"
        for key in ~/.ssh/id_*; do
            if [[ -f "$key" ]] && [[ ! "$key" =~ \.pub$ ]]; then
                local key_name=$(basename "$key")
                echo "   • $key_name"
            fi
        done
    else
        echo "⚠️  No SSH keys directory found"
    fi
}

# Add SSH keys to agent
ssh-unlock() {
    echo "🔑 Adding SSH keys to agent"
    echo ""

    # Check if SSH agent is running
    if [[ -z "$SSH_AUTH_SOCK" ]] || [[ ! -S "$SSH_AUTH_SOCK" ]]; then
        echo "❌ SSH agent is not running"
        echo "   Start it with: eval \$(ssh-agent)"
        return 1
    fi

    # Find SSH keys to add
    local xdg_config="$(get_xdg_config_dir)"
    local keys_to_add=()

    # First try to get keys from machine.config
    if [[ -f "$xdg_config/ssh/machine.config" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ IdentityFile ]]; then
                local key_path=$(echo "$line" | awk '{print $2}' | sed "s|~|$HOME|")
                if [[ -f "$key_path" ]]; then
                    keys_to_add+=("$key_path")
                fi
            fi
        done < "$xdg_config/ssh/machine.config"
    fi

    # If no keys from config, look for standard keys
    if [[ ${#keys_to_add[@]} -eq 0 ]]; then
        for key in ~/.ssh/id_*; do
            if [[ -f "$key" ]] && [[ ! "$key" =~ \.pub$ ]]; then
                keys_to_add+=("$key")
            fi
        done
    fi

    if [[ ${#keys_to_add[@]} -eq 0 ]]; then
        echo "❌ No SSH keys found"
        return 1
    fi

    # Add each key
    local success_count=0
    local fail_count=0

    for key in "${keys_to_add[@]}"; do
        local key_name=$(basename "$key")
        echo "🔓 Adding: $key_name"

        if ssh-add "$key" 2>/dev/null; then
            echo "   ✅ Added successfully"
            ((success_count++))
        else
            echo "   ❌ Failed to add"
            ((fail_count++))
        fi
    done

    echo ""
    if [[ $success_count -gt 0 ]]; then
        echo "✅ Added $success_count key(s) successfully"
        if [[ $fail_count -gt 0 ]]; then
            echo "⚠️  Failed to add $fail_count key(s)"
        fi
        return 0
    else
        echo "❌ Failed to add any keys"
        return 1
    fi
}