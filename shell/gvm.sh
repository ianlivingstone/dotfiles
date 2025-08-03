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
    source "$GVM_ROOT/scripts/gvm"
    
    # Fast filesystem-based checks (no slow GVM commands)
    # Check if configured Go version is installed
    if [[ ! -d "$GVM_ROOT/gos/$GO_VERSION" ]]; then
        show_warning "Go $GO_VERSION not installed"
    fi
    
    # Check if default environment matches configured version
    local current_default=$(grep "gvm_go_name" "$GVM_ROOT/environments/default" 2>/dev/null | cut -d'"' -f2 || echo "none")
    if [[ "$current_default" != "$GO_VERSION" ]]; then
        show_warning "Default Go version is $current_default, expected $GO_VERSION"
    fi
    
    # Use the configured version and ensure it's in PATH
    if [[ -d "$GVM_ROOT/gos/$GO_VERSION" ]]; then
        gvm use "$GO_VERSION" --default > /dev/null 2>&1 || true
        
        # Ensure the specific version's bin directory is in PATH
        add_to_path "$GVM_ROOT/gos/$GO_VERSION/bin"
        
        # Also ensure pkgset bin is in PATH for installed packages
        add_to_path "$GVM_ROOT/pkgsets/$GO_VERSION/global/bin"
    fi
    
elif [[ -d "$HOME/.gvm" ]]; then
    # GVM directory exists but gvm script is missing - corrupted installation
    echo "⚠️  GVM directory found but gvm script is missing. Please reinstall GVM."
else
    # GVM not installed
    echo "❌ GVM not found. Install with: curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash"
fi