# Modular ZSH Configuration
# Load shell modules in the correct order

# Get the directory containing the actual shell modules
# The shell scripts are in the shell/ directory, not the zsh/ directory
# Derive the dotfiles directory from this script's location, resolving symlinks
SCRIPT_PATH="${BASH_SOURCE[0]:-${(%):-%N}}"

# Resolve symlinks to get the real path
if [[ -L "$SCRIPT_PATH" ]]; then
    local target="$(readlink "$SCRIPT_PATH")"
    # Handle relative symlinks by making them absolute
    if [[ "$target" != /* ]]; then
        SCRIPT_PATH="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)/$target"
    else
        SCRIPT_PATH="$target"
    fi
fi

ZSH_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
DOTFILES_DIR="$(dirname "$ZSH_DIR")"
SHELL_DIR="$DOTFILES_DIR/shell"

# Load utility functions
source "$SHELL_DIR/utils.sh"

# Core shell configuration (PATH, completion, basic settings)
source "$SHELL_DIR/core.sh"

# Command aliases  
source "$SHELL_DIR/aliases.sh"

# Programming language environments
source "$SHELL_DIR/languages.sh"

# Utility functions (load early so they're always available)
source "$SHELL_DIR/functions.sh"

# Security validation (must run before agents)
# Note: This is now non-blocking - warnings shown but shell continues
source "$SHELL_DIR/security.sh"
if ! validate_key_security; then
    echo "⚠️  Security validation warnings detected (see above)"
    echo "💡 Run 'fix_security_permissions' to fix permission issues"
    echo "💡 Run 'security_status' to see detailed security status"
    echo ""
fi

# SSH and GPG agent management
source "$SHELL_DIR/agents.sh"

# Shell prompt and status (load last)
source "$SHELL_DIR/prompt.sh"
