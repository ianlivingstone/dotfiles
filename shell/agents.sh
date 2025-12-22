#!/usr/bin/env zsh
# SSH and GPG agent management
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Source shared utilities
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")" && pwd)"
source "$SHELL_DIR/utils.sh"

start_ssh_agent() {
    # Check if SSH agent already started in this shell session
    if [[ "$DOTFILES_SSH_AGENT_STARTED" == "1" ]]; then
        return 0
    fi
    
    # Check if ssh-agent is already running and accessible
    if [[ -n "$SSH_AUTH_SOCK" ]] && ssh-add -l &>/dev/null; then
        export DOTFILES_SSH_AGENT_STARTED=1
        return 0  # Agent is running and accessible
    fi
    
    # Try to connect to existing agent
    local agent_env="$HOME/.ssh/agent-env"
    if [[ -f "$agent_env" ]]; then
        source "$agent_env" > /dev/null
        if ssh-add -l &>/dev/null; then
            return 0  # Successfully connected to existing agent
        fi
    fi
    
    # Start new agent (only show output if starting fails)
    if ! ssh-agent > "$agent_env"; then
        echo "❌ Failed to start SSH agent"
        return 1
    fi
    source "$agent_env" > /dev/null
    
    # Load SSH keys from machine-specific config if available
    local xdg_config="$(get_xdg_config_dir)"
    if [[ -f "$xdg_config/ssh/machine.config" ]]; then
        # Extract IdentityFile paths and lazy-load them
        grep "IdentityFile" "$xdg_config/ssh/machine.config" | while read -r line; do
            local key_path=$(echo "$line" | awk '{print $2}' | sed "s|~|$HOME|")
            if [[ -f "$key_path" ]]; then
                # Use lazy loading with --quiet flag to avoid prompts during shell startup
                # Keys must be in macOS Keychain to load automatically
                lazy_load_ssh_key "$key_path" --quiet || true
            fi
        done
    fi
    
    # Cache that SSH agent has been started
    export DOTFILES_SSH_AGENT_STARTED=1
}

start_gpg_agent() {
    # Always update GPG_TTY (needed when switching terminals)
    export GPG_TTY=$(tty)
    
    # Check if GPG agent already started in this shell session
    if [[ "${DOTFILES_GPG_AGENT_STARTED:-}" == "1" ]]; then
        # Update GPG agent with current TTY
        gpg-connect-agent updatestartuptty /bye &>/dev/null || true
        return 0
    fi
    
    # Set up machine-specific GPG configuration
    local xdg_config="$(get_xdg_config_dir)"
    if [[ -f "$xdg_config/gpg/machine.config" ]]; then
        # Create symlink to machine-specific GPG config if it doesn't exist
        local gpg_home="${GNUPGHOME:-$HOME/.gnupg}"
        if [[ ! -f "$gpg_home/gpg.conf" ]] || [[ ! -L "$gpg_home/gpg.conf" ]]; then
            mkdir -p "$gpg_home"
            ln -sf "$xdg_config/gpg/machine.config" "$gpg_home/gpg.conf"
        fi
    fi
    
    # Check if gpg-agent is running and responsive
    if pgrep -x "gpg-agent" > /dev/null && gpg-connect-agent --quiet /bye &>/dev/null; then
        export DOTFILES_GPG_AGENT_STARTED=1
        return 0  # Agent is running and responsive
    fi
    
    # Start gpg-agent with SSH support
    gpg-connect-agent --quiet /bye &>/dev/null
    if ! pgrep -x "gpg-agent" > /dev/null; then
        eval "$(gpg-agent --daemon --enable-ssh-support --quiet)" > /dev/null
    fi
    
    # Verify it started successfully (only show errors)
    if ! pgrep -x "gpg-agent" > /dev/null || ! gpg-connect-agent --quiet /bye &>/dev/null; then
        echo "❌ Failed to start GPG agent"
        return 1
    fi
    
    # Set SSH_AUTH_SOCK to use gpg-agent for SSH if no ssh-agent
    if [[ -z "$SSH_AUTH_SOCK" ]]; then
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    fi
    
    # Cache that GPG agent has been started
    export DOTFILES_GPG_AGENT_STARTED=1
}

# Start agents
start_ssh_agent
start_gpg_agent