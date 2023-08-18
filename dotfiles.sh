#!/bin/bash

# Dotfiles management script using GNU Stow

set -e

# Get the directory of this script
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of packages to manage
PACKAGES=(
    "shell"
    "git"
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
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Install dotfiles"
    echo "  $0 install      # Install dotfiles"
    echo "  $0 uninstall    # Remove dotfiles"
    echo "  $0 status       # Check status"
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
    
    # Check for optional but recommended tools
    local optional_missing=()
    if ! command -v nvim &> /dev/null; then
        optional_missing+=("nvim")
    fi
    
    if ! command -v tmux &> /dev/null; then
        optional_missing+=("tmux")
    fi
    
    if ! command -v brew &> /dev/null; then
        optional_missing+=("brew")
    fi
    
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
            esac
        done
        echo ""
        echo -e "${YELLOW}Install missing dependencies and try again.${NC}"
        exit 1
    fi
    
    # Report missing optional dependencies
    if [ ${#optional_missing[@]} -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Optional tools not found (recommended):${NC}"
        for dep in "${optional_missing[@]}"; do
            case $dep in
                "nvim")
                    echo -e "  ${YELLOW}•${NC} Neovim: brew install neovim"
                    ;;
                "tmux")
                    echo -e "  ${YELLOW}•${NC} Tmux: brew install tmux"
                    ;;
                "brew")
                    echo -e "  ${YELLOW}•${NC} Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                    ;;
            esac
        done
        echo ""
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
    
    echo -e "${GREEN}✅ Dotfiles installation complete!${NC}"
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
    echo -e "${BLUE}📊 Dotfiles Status${NC}"
    echo ""
    
    cd "$DOTFILES_DIR"
    
    for package in "${PACKAGES[@]}"; do
        if [ -d "$package" ]; then
            echo -e "${YELLOW}Package: $package${NC}"
            
            # Check if package files are linked
            find "$package" -type f | while read -r file; do
                # Convert package file path to home path
                relative_path="${file#$package/}"
                
                # Skip starship.toml as it's handled separately
                if [[ "$relative_path" == "starship.toml" ]]; then
                    continue
                fi
                
                home_file="$HOME/$relative_path"
                
                if [ -L "$home_file" ]; then
                    # It's a symbolic link
                    target=$(readlink "$home_file")
                    # Check if it points to our dotfiles (absolute or relative path)
                    if [[ "$target" == *"$DOTFILES_DIR"* ]] || [[ "$target" == *"dotfiles/$package/"* ]]; then
                        echo -e "  ${GREEN}✓${NC} $relative_path -> symlinked"
                    else
                        echo -e "  ${YELLOW}⚠${NC} $relative_path -> symlinked to different target"
                    fi
                elif [ -f "$home_file" ] && [ -f "$file" ]; then
                    # Check if they're the same file (hard link or identical)
                    if [ "$home_file" -ef "$file" ]; then
                        echo -e "  ${GREEN}✓${NC} $relative_path -> stowed (hard link)"
                    else
                        echo -e "  ${RED}✗${NC} $relative_path -> file exists (not linked)"
                    fi
                elif [ -f "$home_file" ]; then
                    echo -e "  ${RED}✗${NC} $relative_path -> file exists (not stowed)"
                else
                    echo -e "  ${RED}✗${NC} $relative_path -> not found"
                fi
            done
            echo ""
        fi
    done
    
    # Check starship config
    echo -e "${YELLOW}Starship config:${NC}"
    if [ -L ~/.config/starship.toml ]; then
        echo -e "  ${GREEN}✓${NC} starship.toml -> linked"
    elif [ -f ~/.config/starship.toml ]; then
        echo -e "  ${RED}✗${NC} starship.toml -> file exists (not linked)"
    else
        echo -e "  ${RED}✗${NC} starship.toml -> not found"
    fi
}

# Main script logic
case "${1:-install}" in
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