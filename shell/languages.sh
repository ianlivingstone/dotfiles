# Programming language environment setup

# Setup Rust/Cargo
source "$HOME/.cargo/env"

# Setup GVM (Go Version Manager)
if [[ -s "/Users/ianlivingstone/.gvm/scripts/gvm" ]]; then
    source "/Users/ianlivingstone/.gvm/scripts/gvm"
fi

# Setup Go environment (after GVM)
export GOPATH=~/code
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
export GOPRIVATE=github.com/keycardlabs

# Setup Node.js/NVM
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"  # This loads nvm
fi
if [[ -s "$NVM_DIR/bash_completion" ]]; then
    source "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi