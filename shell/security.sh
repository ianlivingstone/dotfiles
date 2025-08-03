# Security validation for SSH and GPG keys

validate_ssh_keys() {
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
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
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
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

# Main security validation function
validate_key_security() {
    if ! validate_ssh_keys; then
        return 1
    fi
    
    if ! validate_gpg_keys; then
        return 1
    fi
    
    return 0
}