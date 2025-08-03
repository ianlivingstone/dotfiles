#!/bin/bash

# Dotfiles management script using GNU Stow

set -e

# Get the directory of this script
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of packages to manage
PACKAGES=(
    "shell"
    "git"
    "ssh"
    "tmux"
    "misc"
    "nvim"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Secure curl command with HTTPS-only enforcement
SECURE_CURL="curl --proto '=https' --tlsv1.2"

show_help() {
    echo "🏠 Dotfiles Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install     Install/link all dotfiles (default)"
    echo "  uninstall   Remove all dotfile symlinks"
    echo "  reinstall   Uninstall then install dotfiles"
    echo "  status      Show status of dotfile symlinks"
    echo "  update      Update development environment versions"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Install dotfiles"
    echo "  $0 install      # Install dotfiles"
    echo "  $0 uninstall    # Remove dotfiles"
    echo "  $0 status       # Check status"
    echo "  $0 update       # Update Node.js and other versions"
}

check_dependencies() {
    local missing_deps=()
    
    # Check for required tools
    if ! command -v stow &> /dev/null; then
        missing_deps+=("stow")
    fi
    
    if ! command -v starship &> /dev/null; then
        missing_deps+=("starship")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v zsh &> /dev/null; then
        missing_deps+=("zsh")
    fi
    
    if ! command -v luarocks &> /dev/null; then
        missing_deps+=("luarocks")
    fi
    
    if ! command -v rg &> /dev/null; then
        missing_deps+=("rg")
    fi
    
    if ! command -v brew &> /dev/null; then
        missing_deps+=("brew")
    fi
    
    if ! command -v nvim &> /dev/null; then
        missing_deps+=("nvim")
    fi
    
    if ! command -v tmux &> /dev/null; then
        missing_deps+=("tmux")
    fi
    
    # Check for development environment managers
    if ! command -v nvm &> /dev/null && [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
        missing_deps+=("nvm")
    fi
    
    if ! command -v gvm &> /dev/null && [[ ! -s "$HOME/.gvm/scripts/gvm" ]]; then
        missing_deps+=("gvm")
    fi
    
    if ! command -v rustup &> /dev/null; then
        missing_deps+=("rustup")
    fi
    
    # Check for optional tools - none currently
    
    # Report missing required dependencies
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "stow")
                    echo -e "  ${RED}•${NC} GNU Stow: brew install stow"
                    ;;
                "starship")
                    echo -e "  ${RED}•${NC} Starship: brew install starship"
                    ;;
                "git")
                    echo -e "  ${RED}•${NC} Git: brew install git"
                    ;;
                "zsh")
                    echo -e "  ${RED}•${NC} Zsh: brew install zsh"
                    ;;
                "luarocks")
                    echo -e "  ${RED}•${NC} Luarocks: brew install luarocks"
                    ;;
                "rg")
                    echo -e "  ${RED}•${NC} Ripgrep: brew install ripgrep"
                    ;;
                "brew")
                    echo -e "  ${RED}•${NC} Homebrew: /bin/bash -c \"\$($SECURE_CURL -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                    ;;
                "nvim")
                    echo -e "  ${RED}•${NC} Neovim: brew install neovim"
                    ;;
                "tmux")
                    echo -e "  ${RED}•${NC} Tmux: brew install tmux"
                    ;;
                "nvm")
                    echo -e "  ${RED}•${NC} NVM: curl --proto '=https' --tlsv1.2 -o- -sSfL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
                    ;;
                "gvm")
                    echo -e "  ${RED}•${NC} GVM: curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash"
                    ;;
                "rustup")
                    echo -e "  ${RED}•${NC} Rustup: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
                    ;;
            esac
        done
        echo ""
        echo -e "${YELLOW}Install missing dependencies and try again.${NC}"
        exit 1
    fi
    
    # Additional setup instructions
    echo -e "${BLUE}💡 After installing dependencies, recommended setup:${NC}"
    echo -e "  ${BLUE}•${NC} Install Node.js: nvm install --lts && nvm use --lts"
    echo ""
}

detect_ssh_keys() {
    echo -e "${BLUE}🔍 Scanning for SSH keys...${NC}"
    
    local ssh_keys=()
    for key in ~/.ssh/id_*; do
        # Check if file exists and is not a .pub file
        if [[ -f "$key" && ! "$key" == *.pub ]]; then
            ssh_keys+=("$key")
        fi
    done
    
    if [ ${#ssh_keys[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No SSH private keys found in ~/.ssh/${NC}"
        echo -e "${BLUE}💡 Generate keys with: ssh-keygen -t ed25519 -C 'your_email@example.com'${NC}"
        echo ""
        return 1
    fi
    
    echo -e "${GREEN}Found SSH keys:${NC}"
    for i in "${!ssh_keys[@]}"; do
        echo -e "  ${GREEN}$((i+1)).${NC} ${ssh_keys[i]}"
    done
    
    echo ""
    echo "Select keys to auto-load on shell startup:"
    echo "  - Enter numbers comma-separated (e.g., 1,3)"
    echo "  - Enter 'all' for all keys"
    echo "  - Enter 'none' to skip SSH key setup"
    read -p "Selection: " selection
    
    local selected_keys=()
    if [[ "$selection" == "all" ]]; then
        selected_keys=("${ssh_keys[@]}")
    elif [[ "$selection" == "none" ]]; then
        return 1
    else
        IFS=',' read -ra indices <<< "$selection"
        for index in "${indices[@]}"; do
            index=$(echo "$index" | xargs) # trim whitespace
            if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 1 ] && [ "$index" -le ${#ssh_keys[@]} ]; then
                selected_keys+=("${ssh_keys[$((index-1))]}")
            fi
        done
    fi
    
    if [ ${#selected_keys[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No valid keys selected${NC}"
        return 1
    fi
    
    # Export selected keys for use in config creation
    SSH_SELECTED_KEYS=("${selected_keys[@]}")
    return 0
}

configure_git_user() {
    echo -e "${BLUE}👤 Configuring Git user information...${NC}"
    echo ""
    
    read -p "Enter your full name for Git commits: " git_name
    read -p "Enter your email address for Git commits: " git_email
    
    if [[ -z "$git_name" || -z "$git_email" ]]; then
        echo -e "${YELLOW}⚠️  Name and email are required for Git${NC}"
        return 1
    fi
    
    GIT_USER_NAME="$git_name"
    GIT_USER_EMAIL="$git_email"
    
    echo -e "${GREEN}✅ Git user configured: $git_name <$git_email>${NC}"
    return 0
}

detect_gpg_keys() {
    echo -e "${BLUE}🔍 Scanning for GPG keys...${NC}"
    
    # Check if gpg is available
    if ! command -v gpg &> /dev/null; then
        echo -e "${YELLOW}⚠️  GPG not found, skipping GPG key setup${NC}"
        return 1
    fi
    
    local gpg_keys=($(gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep '^sec' | awk '{print $2}' | cut -d'/' -f2))
    
    if [ ${#gpg_keys[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No GPG private keys found${NC}"
        echo -e "${BLUE}💡 Generate with: gpg --full-generate-key${NC}"
        echo ""
        return 1
    fi
    
    echo -e "${GREEN}Found GPG keys:${NC}"
    for i in "${!gpg_keys[@]}"; do
        local key_info=$(gpg --list-keys "${gpg_keys[i]}" 2>/dev/null | grep uid | head -1 | sed 's/uid.*] //')
        echo -e "  ${GREEN}$((i+1)).${NC} ${gpg_keys[i]} - $key_info"
    done
    
    echo ""
    echo "Select a key for Git commit signing (or 'none' to skip):"
    read -p "Selection (number or 'none'): " selection
    
    if [[ "$selection" == "none" ]]; then
        return 1
    fi
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#gpg_keys[@]} ]; then
        GPG_SELECTED_KEY="${gpg_keys[$((selection-1))]}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Invalid selection${NC}"
        return 1
    fi
}

configure_machine_keys() {
    local machine_id="$(hostname -s)"
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
    
    echo -e "${BLUE}⚙️  Configuring keys for machine: $machine_id${NC}"
    
    # Create XDG config directories
    mkdir -p "$xdg_config/git"
    mkdir -p "$xdg_config/ssh"
    mkdir -p "$xdg_config/gpg"
    mkdir -p ~/.ssh/sockets  # For SSH connection multiplexing
    
    # Configure Git machine-specific settings
    local git_config="$xdg_config/git/machine.config"
    echo "# Machine-specific Git configuration for: $machine_id" > "$git_config"
    echo "# Generated by dotfiles on $(date)" >> "$git_config"
    echo "" >> "$git_config"
    
    # User name and email (required)
    if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
        echo "[user]" >> "$git_config"
        echo "    name = $GIT_USER_NAME" >> "$git_config"
        echo "    email = $GIT_USER_EMAIL" >> "$git_config"
        
        # Add signing key if selected
        if [[ -n "$GPG_SELECTED_KEY" ]]; then
            echo "    signingkey = $GPG_SELECTED_KEY" >> "$git_config"
        fi
        
        echo -e "${GREEN}✅ Git user and signing configuration saved${NC}"
    else
        echo -e "${RED}❌ Git user configuration missing${NC}"
    fi
    
    if [[ -z "$GPG_SELECTED_KEY" ]]; then
        echo "" >> "$git_config"
        echo "# No GPG key selected - commits will fail due to required signing" >> "$git_config"
        echo -e "${YELLOW}⚠️  No GPG key configured - commits will fail due to required signing${NC}"
        echo -e "${BLUE}💡 Generate a GPG key with: gpg --full-generate-key${NC}"
    fi
    
    # Save GPG key selection for agent use
    local gpg_config="$xdg_config/gpg/machine.config"
    echo "# Machine-specific GPG configuration for: $machine_id" > "$gpg_config"
    echo "# Generated by dotfiles on $(date)" >> "$gpg_config"
    echo "" >> "$gpg_config"
    
    if [[ -n "$GPG_SELECTED_KEY" ]]; then
        echo "# Selected GPG key for this machine" >> "$gpg_config"
        echo "default-key $GPG_SELECTED_KEY" >> "$gpg_config"
        echo -e "${GREEN}✅ GPG key preference saved${NC}"
    else
        echo "# No GPG key selected" >> "$gpg_config"
        echo -e "${YELLOW}⚠️  No GPG key preference saved${NC}"
    fi
    
    # Configure SSH machine-specific settings
    local ssh_config="$xdg_config/ssh/machine.config"
    echo "# Machine-specific SSH configuration for: $machine_id" > "$ssh_config"
    echo "# Generated by dotfiles on $(date)" >> "$ssh_config"
    echo "" >> "$ssh_config"
    
    if [[ -n "${SSH_SELECTED_KEYS[@]}" ]]; then
        # Group keys by hostname pattern for cleaner config
        echo "# Default identity files for this machine" >> "$ssh_config"
        echo "Host *" >> "$ssh_config"
        for key in "${SSH_SELECTED_KEYS[@]}"; do
            echo "    IdentityFile $key" >> "$ssh_config"
        done
        echo "    IdentitiesOnly yes" >> "$ssh_config"
        echo "" >> "$ssh_config"
        echo -e "${GREEN}✅ SSH key configuration saved${NC}"
    else
        echo "# No SSH keys selected" >> "$ssh_config"
    fi
    
    echo -e "${GREEN}✅ Machine configuration saved${NC}"
    echo -e "${BLUE}📍 Git config: $git_config${NC}"
    echo -e "${BLUE}📍 SSH config: $ssh_config${NC}"
}

configure_hostname() {
    echo -e "${BLUE}🏠 Configuring machine hostname...${NC}"
    echo ""
    
    local current_hostname=$(hostname -s)
    echo -e "${YELLOW}Current hostname: $current_hostname${NC}"
    
    read -p "Enter new hostname (or press Enter to keep current): " new_hostname
    
    if [[ -z "$new_hostname" ]]; then
        echo -e "${YELLOW}⚠️  Keeping current hostname: $current_hostname${NC}"
        return 0
    fi
    
    # Validate hostname format
    if [[ ! "$new_hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then
        echo -e "${RED}❌ Invalid hostname format. Use only letters, numbers, and hyphens${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Setting hostname to: $new_hostname${NC}"
    
    # Set hostname (requires sudo)
    if sudo scutil --set HostName "$new_hostname" && \
       sudo scutil --set LocalHostName "$new_hostname" && \
       sudo scutil --set ComputerName "$new_hostname"; then
        echo -e "${GREEN}✅ Hostname set to: $new_hostname${NC}"
        echo -e "${BLUE}💡 Changes will take effect after restart${NC}"
    else
        echo -e "${RED}❌ Failed to set hostname (check sudo permissions)${NC}"
        return 1
    fi
}

install_dotfiles() {
    echo -e "${GREEN}🏠 Installing dotfiles...${NC}"
    
    check_dependencies
    
    echo -e "${BLUE}📁 Using dotfiles directory: $DOTFILES_DIR${NC}"
    
    # Change to dotfiles directory
    cd "$DOTFILES_DIR"
    
    # Use stow to link each package directory
    echo -e "${YELLOW}🔗 Stowing all dotfiles...${NC}"
    for package in "${PACKAGES[@]}"; do
        if [ -d "$package" ]; then
            echo "   Stowing $package..."
            stow --restow --target="$HOME" "$package"
        fi
    done
    
    # Link starship config
    echo -e "${YELLOW}🔗 Linking starship config...${NC}"
    mkdir -p ~/.config
    ln -sf "$DOTFILES_DIR/misc/starship.toml" ~/.config/starship.toml
    
    echo ""
    echo -e "${BLUE}🔐 Setting up SSH and GPG keys for this machine...${NC}"
    echo ""
    
    # Initialize variables for configuration
    SSH_SELECTED_KEYS=()
    GPG_SELECTED_KEY=""
    GIT_USER_NAME=""
    GIT_USER_EMAIL=""
    
    # Configure Git user information
    if configure_git_user; then
        echo -e "${GREEN}✅ Git user information configured${NC}"
    else
        echo -e "${RED}❌ Git user configuration required${NC}"
        return 1
    fi
    
    echo ""
    
    # Detect and configure SSH keys
    if detect_ssh_keys; then
        echo -e "${GREEN}✅ SSH keys selected${NC}"
    fi
    
    echo ""
    
    # Detect and configure GPG keys
    if detect_gpg_keys; then
        echo -e "${GREEN}✅ GPG key selected${NC}"
    fi
    
    echo ""
    
    # Configure machine-specific settings
    configure_machine_keys
    
    echo ""
    
    # Configure hostname
    configure_hostname
    
    echo ""
    echo -e "${GREEN}✅ Dotfiles installation complete!${NC}"
    
    # Update development environment versions
    echo ""
    update_environment
    
    echo ""
    echo -e "${BLUE}🔄 Please restart your shell or run 'source ~/.zshrc' to apply changes${NC}"
}

uninstall_dotfiles() {
    echo -e "${RED}🗑️  Uninstalling dotfiles...${NC}"
    
    # Only check for stow for uninstall
    if ! command -v stow &> /dev/null; then
        echo -e "${RED}❌ GNU Stow is not installed. Cannot uninstall.${NC}"
        exit 1
    fi
    
    # Change to dotfiles directory
    cd "$DOTFILES_DIR"
    
    # Unstow all packages 
    echo -e "${YELLOW}🔗 Unstowing all dotfiles...${NC}"
    for package in "${PACKAGES[@]}"; do
        if [ -d "$package" ]; then
            echo "   Unstowing $package..."
            stow --delete --target="$HOME" "$package" 2>/dev/null || true
        fi
    done
    
    # Fallback: manually remove any remaining symlinks that point to our dotfiles
    echo -e "${YELLOW}🔗 Cleaning up any remaining symlinks...${NC}"
    for package in "${PACKAGES[@]}"; do
        if [ -d "$package" ]; then
            find "$package" -type f | while read -r file; do
                relative_path="${file#$package/}"
                home_file="$HOME/$relative_path"
                
                # Skip starship.toml as it's handled separately
                if [[ "$relative_path" == "starship.toml" ]]; then
                    continue
                fi
                
                if [ -L "$home_file" ]; then
                    target=$(readlink "$home_file")
                    if [[ "$target" == *"$DOTFILES_DIR"* ]]; then
                        echo "   Removing $relative_path"
                        rm -f "$home_file"
                    fi
                fi
            done
        fi
    done
    
    # Remove starship config
    echo -e "${YELLOW}🔗 Removing starship config...${NC}"
    rm -f ~/.config/starship.toml
    
    echo -e "${GREEN}✅ Dotfiles uninstall complete!${NC}"
    echo -e "${BLUE}🔄 Please restart your shell to apply changes${NC}"
}

show_status() {
    # Source the shell functions to get access to dotfiles_status
    source "$DOTFILES_DIR/shell/functions.sh"
    
    # Call the unified status function
    dotfiles_status
}

update_environment() {
    echo -e "${GREEN}🔄 Updating Development Environment...${NC}"
    
    # Load NVM configuration
    if [[ -f "$DOTFILES_DIR/shell/nvm.config" ]]; then
        source "$DOTFILES_DIR/shell/nvm.config"
        
        # Ensure NVM is loaded
        if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
            source "$HOME/.nvm/nvm.sh"
            
            echo -e "${BLUE}📦 Installing Node.js $NODE_VERSION...${NC}"
            nvm install "$NODE_VERSION"
            
            echo -e "${BLUE}🔧 Setting Node.js $NODE_VERSION as default...${NC}"
            nvm alias default "$NODE_VERSION"
            
            echo -e "${GREEN}✅ Node.js environment updated!${NC}"
        else
            echo -e "${RED}❌ NVM not found. Please install NVM first.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  NVM config not found${NC}"
    fi
}

# Main script logic
case "${1:-help}" in
    "install")
        install_dotfiles
        ;;
    "uninstall")
        uninstall_dotfiles
        ;;
    "reinstall")
        uninstall_dotfiles
        echo ""
        install_dotfiles
        ;;
    "status")
        show_status
        ;;
    "update")
        update_environment
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac