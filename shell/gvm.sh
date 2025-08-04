# GVM (Go Version Manager) setup and configuration

# Load utility functions
source "$(cd "$(dirname "${(%):-%N}")" && pwd)/utils.sh"

# Get the directory containing this script
MODULE_DIR="$(get_shell_dir)"

# Load Go version from config
load_config "$MODULE_DIR/gvm.config" "GO_VERSION" "go1.24.1"

# Setup GVM directory
export GVM_ROOT="$HOME/.gvm"

# Load GVM if it exists
if [[ -s "$GVM_ROOT/scripts/gvm" ]]; then
    # Source GVM to make gvm command available in shell
    source "$GVM_ROOT/scripts/gvm" 2>/dev/null || {
        echo "⚠️  Failed to source GVM scripts, but continuing..."
    }
    
    # Fast filesystem-based checks (no slow GVM commands)
    # Check if configured Go version is installed
    if [[ ! -d "$GVM_ROOT/gos/$GO_VERSION" ]]; then
        show_warning "Go $GO_VERSION not installed"
    fi
    
    # Check if default environment matches configured version
    local current_default=""
    if [[ -f "$GVM_ROOT/environments/default" ]]; then
        current_default=$(grep "gvm_go_name" "$GVM_ROOT/environments/default" 2>/dev/null | cut -d'"' -f2 || echo "")
    fi
    
    if [[ -z "$current_default" ]]; then
        show_warning "No default Go version set, expected $GO_VERSION"
    elif [[ "$current_default" != "$GO_VERSION" ]]; then
        show_warning "Default Go version is $current_default, expected $GO_VERSION"
    fi
    
    # Setup Go environment if version is installed
    if [[ -d "$GVM_ROOT/gos/$GO_VERSION" ]]; then
        # Only use gvm use if the current default doesn't match our target
        if [[ "$current_default" != "$GO_VERSION" ]]; then
            # Use gvm use to set the version (only if GVM functions are available)
            if declare -f gvm >/dev/null 2>&1; then
                gvm use "$GO_VERSION" --default >/dev/null 2>&1 || {
                    echo "⚠️  Failed to set Go $GO_VERSION as default via gvm use"
                }
            fi
        fi
        
        # Always source the default environment to ensure variables are set
        if [[ -f "$GVM_ROOT/environments/default" ]]; then
            source "$GVM_ROOT/environments/default"
        fi
        
        # Ensure Go paths are in PATH
        add_to_path "$GVM_ROOT/gos/$GO_VERSION/bin"
        add_to_path "$GVM_ROOT/pkgsets/$GO_VERSION/global/bin"
        
        # Set Go environment variables as fallback
        export GOROOT="${GOROOT:-$GVM_ROOT/gos/$GO_VERSION}"
        export GOPATH="${GOPATH:-$GVM_ROOT/pkgsets/$GO_VERSION/global}"
    fi
    
elif [[ -d "$HOME/.gvm" ]]; then
    # GVM directory exists but gvm script is missing - corrupted installation
    echo "⚠️  GVM directory found but gvm script is missing. Please reinstall GVM."
else
    # GVM not installed
    show_warning "GVM not installed. Install GVM first, then run: dotfiles update"
fi