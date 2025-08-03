# Programming language environment setup

# Get the directory containing this script (use zsh-compatible approach)
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${(%):-%x}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    # Fallback to known shell directory location
    SCRIPT_DIR="$HOME/code/src/github.com/ianlivingstone/dotfiles/shell"
fi

# Setup Rust/Cargo
source "$HOME/.cargo/env"

# Setup GVM (Go Version Manager)
if [[ -s "$HOME/.gvm/scripts/gvm" ]]; then
    source "$HOME/.gvm/scripts/gvm"
fi

# Setup Go environment (after GVM)
export GOPATH=~/code
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
export GOPRIVATE=github.com/keycardlabs

# Setup Node.js/NVM (using dedicated nvm module)
source "$SCRIPT_DIR/nvm.sh"