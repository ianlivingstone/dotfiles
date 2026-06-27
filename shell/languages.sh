#!/usr/bin/env zsh
# Programming language environment setup
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Note: SHELL_DIR is set by .zshrc before sourcing this file
# It contains the path to the shell modules directory

# Setup Rust/Cargo (using dedicated rust module)
if [[ -f "$SHELL_DIR/rust.sh" ]]; then
    source "$SHELL_DIR/rust.sh"
else
    echo "⚠️  Rust module not found at: $SHELL_DIR/rust.sh"
fi

# Setup GVM/Go (using dedicated gvm module)
if [[ -f "$SHELL_DIR/gvm.sh" ]]; then
    source "$SHELL_DIR/gvm.sh"
else
    echo "⚠️  GVM module not found at: $SHELL_DIR/gvm.sh"
fi

# Machine/org-specific shell env (e.g. GOPRIVATE for private Go modules) lives outside
# the repo so org names / private hosts aren't committed to a shareable dotfiles repo.
# Put `export GOPRIVATE=...` etc. in this gitignored, machine-local file:
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shell/machine.env" ]] && \
    source "${XDG_CONFIG_HOME:-$HOME/.config}/shell/machine.env"

# Setup Node.js/NVM (using dedicated nvm module)
if [[ -f "$SHELL_DIR/nvm.sh" ]]; then
    source "$SHELL_DIR/nvm.sh"
else
    echo "⚠️  NVM module not found at: $SHELL_DIR/nvm.sh"
fi

# Setup Python/uv (using dedicated uv module)
if [[ -f "$SHELL_DIR/uv.sh" ]]; then
    source "$SHELL_DIR/uv.sh"
else
    echo "⚠️  uv module not found at: $SHELL_DIR/uv.sh"
fi