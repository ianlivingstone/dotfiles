#!/usr/bin/env zsh
# Rust/Cargo setup and configuration
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Load utility functions
source "$(cd "$(dirname "${(%):-%N}")" && pwd)/utils.sh"

# Setup Rust environment if rustup is installed
if command -v rustup &>/dev/null; then
    # Source cargo environment if it exists
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi
    
    # Ensure .cargo/bin is in PATH
    add_to_path "$HOME/.cargo/bin"
    
elif [[ -f "$HOME/.cargo/env" ]]; then
    # Rustup not in PATH but cargo env file exists - source it
    source "$HOME/.cargo/env"
    add_to_path "$HOME/.cargo/bin"
    
else
    # Neither rustup nor cargo env found
    show_warning "Rust/Cargo not installed"
fi