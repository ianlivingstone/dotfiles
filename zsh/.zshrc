# Modular ZSH Configuration
# Load shell modules in the correct order

# Get the directory containing the actual shell modules
# The shell scripts are in the shell/ directory, not the zsh/ directory
DOTFILES_DIR="/Users/ian/code/src/github.com/ianlivingstone/dotfiles"
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
if ! source "$SHELL_DIR/security.sh" || ! validate_key_security; then
    echo "🚨 Shell startup aborted due to security validation failure"
    echo "💡 Fix the key encryption issues above and restart your shell"
    echo "💡 You can still run 'security_status' to check your current setup"
    return 1
fi

# SSH and GPG agent management
source "$SHELL_DIR/agents.sh"

# Shell prompt and status (load last)
source "$SHELL_DIR/prompt.sh"
