#!/usr/bin/env zsh
# NVM (Node Version Manager) setup and configuration
# SOURCED MODULE: Uses graceful error handling, never use set -e

# ==============================================================================
# GLOBAL GUARD: Prevent the entire script/module from double-loading
# ==============================================================================
if [[ "${DOTFILES_NVM_MODULE_INITIALIZED}" == "1" ]]; then
    return 0
fi
# Not exported on purpose: nested shells should re-run this cheap setup so the
# nvm() wrapper and the pinned-version PATH entry exist there too. (Exporting it
# made child shells skip the module entirely, leaving nvm undefined.)
typeset -g DOTFILES_NVM_MODULE_INITIALIZED=1

# Load utility functions safely
# Using Zsh-native modifiers (:a:h) to securely find absolute parent directory path
typeset -g MODULE_DIR="${${(%):-%N}:a:h}"
if [[ -s "${MODULE_DIR}/utils.sh" ]]; then
    source "${MODULE_DIR}/utils.sh"
fi

# Get NODE_VERSION from versions.config strictly
typeset -g NODE_VERSION
NODE_VERSION=$(get_version_requirement "node" 2>/dev/null)

# Hard failure block: Exit script execution if Node configuration is missing
if [[ -z "$NODE_VERSION" ]]; then
    if typeset -f show_error >/dev/null; then
        show_error "Failed to retrieve Node.js version requirement from configuration."
    else
        echo "❌ [NVM Module Error]: Failed to retrieve Node.js version requirement from configuration." >&2
    fi
    return 1
fi

# Setup NVM directory following strict XDG standards cleanly
export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"

# Load NVM lazily - only when first needed
load_nvm() {
    # Check if NVM already loaded
    if [[ "$DOTFILES_NVM_LOADED" == "1" ]]; then
        return 0
    fi

    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # Set guard immediately before sourcing to prevent race condition loops
        export DOTFILES_NVM_LOADED=1
        
        # Source NVM exactly once using the dynamic directory configuration
        source "$NVM_DIR/nvm.sh"
        
        # Load bash completion from dynamic directory path
        if [[ -s "$NVM_DIR/bash_completion" ]]; then
            source "$NVM_DIR/bash_completion"
        fi
        
        # Clean up wrapper functions for binaries, but leave 'nvm' alive as a functional reference
        unset -f node npm npx corepack yarn pnpm 2>/dev/null
        
        return 0
    fi
    return 1
}

# Wrap structural filesystem validation into an isolated execution scope
_init_dotfiles_nvm() {
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # nvm subcommands are always lazy-loaded (sourcing nvm.sh is ~0.6s)
        nvm() { load_nvm && nvm "$@"; }

        # Fast filesystem-based checks using $NVM_DIR
        # Check if configured Node version is installed
        if [[ ! -d "$NVM_DIR/versions/node/$NODE_VERSION" ]]; then
            show_warning "Node.js $NODE_VERSION not installed"
            # Pinned version missing: fall back to lazy wrappers so node/npm/npx
            # still work via nvm's default version (load cost paid on first use).
            node() { load_nvm && node "$@"; }
            npm() { load_nvm && npm "$@"; }
            npx() { load_nvm && npx "$@"; }
        else
            # Pinned version installed: put its bin dir directly on PATH so node/npm/npx
            # resolve to the real binaries with zero lazy-load cost on first call.
            # No wrapper functions needed — this removes the slow-first-command stall.
            add_to_path "$NVM_DIR/versions/node/$NODE_VERSION/bin"
        fi
        
        # Check if default alias matches configured version safely using scoped variables
        local current_default
        current_default=$(cat "$NVM_DIR/alias/default" 2>/dev/null || echo "none")
        if [[ "$current_default" != "$NODE_VERSION" ]]; then
            show_warning "Default Node.js version is $current_default, expected $NODE_VERSION"
        fi
        
    elif [[ -d "$NVM_DIR" ]]; then
        # NVM directory exists but nvm.sh is missing - corrupted installation
        echo "⚠️  NVM directory found at $NVM_DIR but nvm.sh is missing. Please reinstall NVM."
    else
        # NVM not installed - Verified environment string alignment for shell installation pipes
        echo "❌ NVM not found at $NVM_DIR. Install with: export NVM_DIR=\"$NVM_DIR\" && curl --proto '=https' --tlsv1.2 -o- -sSfL https://githubusercontent.com | bash"
    fi
}

# Run execution block and clean up its function allocation definition immediately
_init_dotfiles_nvm
unset -f _init_dotfiles_nvm
