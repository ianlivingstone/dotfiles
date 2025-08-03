# Utility functions

# Agent status checking function
agents_status() {
    echo "🔐 Agent Status Check"
    echo "===================="
    
    # SSH Agent Status
    if [[ -n "$SSH_AUTH_SOCK" ]] && ssh-add -l &>/dev/null; then
        echo "✅ SSH Agent: Running"
        local key_count=$(ssh-add -l 2>/dev/null | wc -l)
        echo "   └── Keys loaded: $key_count"
        if [[ $key_count -gt 0 ]]; then
            ssh-add -l | sed 's/^/       /'
        fi
    else
        echo "❌ SSH Agent: Not running or no keys loaded"
    fi
    
    echo
    
    # GPG Agent Status  
    if pgrep -x "gpg-agent" > /dev/null && gpg-connect-agent --quiet /bye &>/dev/null; then
        echo "✅ GPG Agent: Running"
        
        # Check for GPG keys
        local gpg_keys=$(gpg --list-secret-keys --keyid-format=short 2>/dev/null | grep '^sec' | wc -l)
        echo "   └── Secret keys available: $gpg_keys"
        
        # Check GPG TTY
        if [[ -n "$GPG_TTY" ]]; then
            echo "   └── GPG_TTY: $GPG_TTY"
        else
            echo "   └── GPG_TTY: Not set"
        fi
    else
        echo "❌ GPG Agent: Not running or not responsive"
    fi
    
    echo
    
    # GitHub SSH connectivity test
    echo "🌐 GitHub SSH Test:"
    if ssh -T git@github.com -o ConnectTimeout=5 -o BatchMode=yes 2>&1 | grep -q "successfully authenticated"; then
        echo "✅ GitHub SSH: Connected"
    else
        echo "❌ GitHub SSH: Connection failed"
    fi
}