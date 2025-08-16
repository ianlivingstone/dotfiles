#!/usr/bin/env zsh
# Tmux management functions for dotfiles system
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Install Tmux Plugin Manager (TPM) and plugins
install_tmux_plugins() {
    echo "📦 Setting up Tmux Plugin Manager..."
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ ! -d "$tpm_dir" ]]; then
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        echo "✅ TPM installed"
    else
        echo "✅ TPM already installed"
    fi
    
    # Install tmux plugins automatically
    if [[ -f "$tpm_dir/bin/install_plugins" ]]; then
        echo "📦 Installing tmux plugins..."
        "$tpm_dir/bin/install_plugins"
        echo "✅ Tmux plugins installed"
    fi
}

# Update tmux plugins
update_tmux_plugins() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" && -f "$tpm_dir/bin/update_plugins" ]]; then
        echo "📦 Updating tmux plugins..."
        "$tpm_dir/bin/update_plugins" all
        echo "✅ Tmux plugins updated"
    else
        echo "⚠️  TPM not installed, skipping tmux plugin updates"
    fi
}