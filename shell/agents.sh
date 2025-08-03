# SSH and GPG agent management

start_ssh_agent() {
    # Check if ssh-agent is already running and accessible
    if [[ -n "$SSH_AUTH_SOCK" ]] && ssh-add -l &>/dev/null; then
        echo "🔐 SSH Agent: Already running"
        return 0  # Agent is running and accessible
    fi
    
    # Try to connect to existing agent
    local agent_env="$HOME/.ssh/agent-env"
    if [[ -f "$agent_env" ]]; then
        source "$agent_env" > /dev/null
        if ssh-add -l &>/dev/null; then
            echo "🔐 SSH Agent: Connected to existing agent"
            return 0  # Successfully connected to existing agent
        fi
    fi
    
    # Start new agent
    echo "🔐 SSH Agent: Starting new agent..."
    ssh-agent > "$agent_env"
    source "$agent_env" > /dev/null
    echo "🔐 SSH Agent: ✅ Started successfully"
    
    # Load SSH keys from machine-specific config if available
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
    if [[ -f "$xdg_config/ssh/machine.config" ]]; then
        echo "🔑 Loading SSH keys from machine configuration..."
        # Extract IdentityFile paths and add them
        grep "IdentityFile" "$xdg_config/ssh/machine.config" | while read -r line; do
            local key_path=$(echo "$line" | awk '{print $2}' | sed "s|~|$HOME|")
            if [[ -f "$key_path" ]]; then
                local key_name=$(basename "$key_path")
                echo "   Loading key: $key_name"
                if ssh-add "$key_path" 2>/dev/null; then
                    echo "   ✅ Successfully loaded: $key_name"
                else
                    echo "   ❌ Failed to load or key already loaded: $key_name"
                fi
            fi
        done
    fi
}

start_gpg_agent() {
    # Set GPG TTY for proper operation
    export GPG_TTY=$(tty)
    
    # Check if gpg-agent is running and responsive
    if pgrep -x "gpg-agent" > /dev/null && gpg-connect-agent --quiet /bye &>/dev/null; then
        echo "🔐 GPG Agent: Already running"
        return 0  # Agent is running and responsive
    fi
    
    # Start gpg-agent with SSH support
    echo "🔐 GPG Agent: Starting agent..."
    gpg-connect-agent --quiet /bye &>/dev/null
    if ! pgrep -x "gpg-agent" > /dev/null; then
        eval "$(gpg-agent --daemon --enable-ssh-support --quiet)" > /dev/null
    fi
    
    # Verify it started successfully
    if pgrep -x "gpg-agent" > /dev/null && gpg-connect-agent --quiet /bye &>/dev/null; then
        echo "🔐 GPG Agent: ✅ Started successfully"
    else
        echo "🔐 GPG Agent: ❌ Failed to start"
    fi
    
    # Set SSH_AUTH_SOCK to use gpg-agent for SSH if no ssh-agent
    if [[ -z "$SSH_AUTH_SOCK" ]]; then
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    fi
}

# Start agents
start_ssh_agent
start_gpg_agent