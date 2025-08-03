# Programming language environment setup

# Note: SHELL_DIR is set by .zshrc before sourcing this file
# It contains the path to the shell modules directory

# Setup Rust/Cargo
source "$HOME/.cargo/env"

# Setup GVM/Go (using dedicated gvm module)
if [[ -f "$SHELL_DIR/gvm.sh" ]]; then
    source "$SHELL_DIR/gvm.sh"
else
    echo "⚠️  GVM module not found at: $SHELL_DIR/gvm.sh"
fi

# Additional Go configuration
export GOPRIVATE=github.com/keycardlabs

# Setup Node.js/NVM (using dedicated nvm module)
if [[ -f "$SHELL_DIR/nvm.sh" ]]; then
    source "$SHELL_DIR/nvm.sh"
else
    echo "⚠️  NVM module not found at: $SHELL_DIR/nvm.sh"
fi