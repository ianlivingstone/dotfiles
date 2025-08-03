# NVM (Node Version Manager) setup and configuration

# Get the directory containing this script  
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load node version from config
if [[ -f "$SCRIPT_DIR/nvm.config" ]]; then
    source "$SCRIPT_DIR/nvm.config"
else
    # Fallback if config file is missing
    NODE_VERSION="v24.1.0"
fi

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
        echo "⚠️  Node.js $NODE_VERSION not installed. Run: dotfiles update"
    fi
    
    # Check if default alias matches configured version
    local current_default=$(cat "$NVM_DIR/alias/default" 2>/dev/null || echo "none")
    if [[ "$current_default" != "$NODE_VERSION" ]]; then
        echo "⚠️  Default Node.js version is $current_default, expected $NODE_VERSION. Run: dotfiles update"
    fi
    
    # Try to use the configured version (silent if not available)
    nvm use "$NODE_VERSION" > /dev/null 2>&1 || true
    
elif [[ -d "$HOME/.nvm" ]]; then
    # NVM directory exists but nvm.sh is missing - corrupted installation
    echo "⚠️  NVM directory found but nvm.sh is missing. Please reinstall NVM."
else
    # NVM not installed
    echo "❌ NVM not found. Install with: curl --proto '=https' --tlsv1.2 -o- -sSfL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
fi