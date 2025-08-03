# NVM (Node Version Manager) setup and configuration

# Load utility functions
source "$(cd "$(dirname "${(%):-%N}")" && pwd)/utils.sh"

# Get the directory containing this script
MODULE_DIR="$(get_shell_dir)"

# Load node version from config
load_config "$MODULE_DIR/nvm.config" "NODE_VERSION" "v24.1.0"

# Setup NVM directory
export NVM_DIR="$HOME/.nvm"

# Load NVM if it exists
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
    
    # Load bash completion
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
        source "$NVM_DIR/bash_completion"
    fi
    
    # Fast filesystem-based checks (no slow NVM commands)
    # Check if configured Node version is installed
    if [[ ! -d "$NVM_DIR/versions/node/$NODE_VERSION" ]]; then
        show_warning "Node.js $NODE_VERSION not installed"
    fi
    
    # Check if default alias matches configured version
    local current_default=$(cat "$NVM_DIR/alias/default" 2>/dev/null || echo "none")
    if [[ "$current_default" != "$NODE_VERSION" ]]; then
        show_warning "Default Node.js version is $current_default, expected $NODE_VERSION"
    fi
    
    # Use the configured version and ensure it's in PATH
    if [[ -d "$NVM_DIR/versions/node/$NODE_VERSION" ]]; then
        nvm use "$NODE_VERSION" > /dev/null 2>&1 || true
        
        # Ensure the specific version's bin directory is in PATH
        add_to_path "$NVM_DIR/versions/node/$NODE_VERSION/bin"
    fi
    
elif [[ -d "$HOME/.nvm" ]]; then
    # NVM directory exists but nvm.sh is missing - corrupted installation
    echo "⚠️  NVM directory found but nvm.sh is missing. Please reinstall NVM."
else
    # NVM not installed
    echo "❌ NVM not found. Install with: curl --proto '=https' --tlsv1.2 -o- -sSfL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
fi