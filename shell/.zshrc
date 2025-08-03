# Modular ZSH Configuration
# Load shell modules in the correct order

# Get the directory containing the actual shell modules
# Since this file is symlinked, we need to resolve the real path
if [[ -L "${(%):-%N}" ]]; then
    # If this file is a symlink, get the directory of the target
    SHELL_DIR="$(dirname "$(readlink "${(%):-%N}")")"
else
    # If not a symlink, get the directory of this file
    SHELL_DIR="${0:A:h}"
fi

# Core shell configuration (PATH, completion, basic settings)
source "$SHELL_DIR/core.sh"

# Command aliases  
source "$SHELL_DIR/aliases.sh"

# Programming language environments
source "$SHELL_DIR/languages.sh"

# SSH and GPG agent management
source "$SHELL_DIR/agents.sh"

# Utility functions
source "$SHELL_DIR/functions.sh"

# Shell prompt and status (load last)
source "$SHELL_DIR/prompt.sh"
