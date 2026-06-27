#!/usr/bin/env zsh

# Dotfiles management script using GNU Stow

set -euo pipefail
trap 'echo "❌ Installation failed at line $LINENO" >&2; exit 1' ERR

# Get the directory of this script
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Source utilities for consistent XDG handling
source "$DOTFILES_DIR/shell/utils.sh"

# XDG Base Directory - use centralized function
XDG_CONFIG_DIR="$(get_xdg_config_dir)"

# Read packages from config file
PACKAGES=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments (use if instead of && to avoid set -e issues)
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    # Safe variable expansion without eval
    line="${line/#\~/$HOME}"
    line="${line//\$HOME/$HOME}"
    line="${line//\$XDG_CONFIG_DIR/$XDG_CONFIG_DIR}"
    PACKAGES+=("$line")
done < "$DOTFILES_DIR/packages.config"

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
    echo "  update      Bring tools to pinned versions (versions.config + Brewfile)"
    echo "  upgrade     Upgrade everything to latest + record new pins in versions.config"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Install dotfiles"
    echo "  $0 install      # Install dotfiles"
    echo "  $0 uninstall    # Remove dotfiles"
    echo "  $0 status       # Check status"
    echo "  $0 update       # Converge tools to pinned versions"
    echo "  $0 upgrade      # Upgrade everything to latest"
}

check_dependencies() {
    local auto_install="${1:-false}"
    local missing_deps=()
    local installable_deps=()

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

    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi

    if ! command -v brew &> /dev/null; then
        missing_deps+=("brew")
    fi

    if ! command -v just &> /dev/null; then
        missing_deps+=("just")
    fi

    if ! command -v duckdb &> /dev/null; then
        missing_deps+=("duckdb")
    fi

    if ! command -v nvim &> /dev/null; then
        missing_deps+=("nvim")
    fi

    if ! command -v tmux &> /dev/null; then
        missing_deps+=("tmux")
    fi

    if ! command -v tig &> /dev/null; then
        missing_deps+=("tig")
    fi

    if ! command -v tree-sitter &> /dev/null; then
        missing_deps+=("tree-sitter")
    fi

    if ! command -v gh &> /dev/null; then
        missing_deps+=("gh")
    fi

    if ! command -v jj &> /dev/null; then
        missing_deps+=("jj")
    fi

    if ! command -v shellcheck &> /dev/null; then
        missing_deps+=("shellcheck")
    fi

    # Note: Python is managed by uv (checked in shell/uv.sh module)

    # Check for Go tools (can be auto-installed)
    if ! command -v gopls &> /dev/null; then
        if [[ "$auto_install" == "true" ]] && command -v go &> /dev/null; then
            installable_deps+=("gopls")
        else
            missing_deps+=("gopls")
        fi
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

    # Check for uv (managed by Homebrew — see Brewfile; installed by install/update)
    if ! command -v uv &> /dev/null; then
        missing_deps+=("uv")
    fi

    # Check for security tools
    if ! command -v gpg &> /dev/null; then
        missing_deps+=("gpg")
    fi

    # Auto-install if requested
    if [[ "$auto_install" == "true" ]] && [[ ${#installable_deps[@]} -gt 0 ]]; then
        echo -e "${BLUE}📦 Auto-installing missing dependencies...${NC}"
        echo ""

        for dep in "${installable_deps[@]}"; do
            case "$dep" in
                gopls)
                    echo -e "${YELLOW}⚠️  gopls not found, installing...${NC}"
                    if go install golang.org/x/tools/gopls@latest; then
                        echo -e "${GREEN}✅ gopls installed successfully!${NC}"
                    else
                        echo -e "${RED}❌ Failed to install gopls${NC}"
                        missing_deps+=("gopls")
                    fi
                    ;;
            esac
        done

        echo ""
    fi

    # Check for containerization tools
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    else
        # Validate Docker version (requires 28+)
        local docker_version=$(docker --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -1)
        if [[ -n "$docker_version" ]]; then
            local major_version=${docker_version%%.*}
            if [[ $major_version -lt 28 ]]; then
                echo -e "${YELLOW}⚠️  Docker version $docker_version found, but 28+ required${NC}"
                missing_deps+=("docker-upgrade")
            fi
        fi
    fi

    # Check for optional tools - none currently

    # Report missing required dependencies
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing required dependencies:${NC}"
        # Tools declared in the Brewfile are installed by `./dotfiles.sh install`
        # (which runs `brew bundle`); collect them and print one pointer instead of
        # a separate `brew install X` per tool. Tools installed by other means keep
        # their specific one-line install command.
        local brew_missing=()
        for dep in "${missing_deps[@]}"; do
            case $dep in
                stow|starship|git|zsh|luarocks|rg|jq|just|duckdb|nvim|tmux|tig|tree-sitter|gh|jj|shellcheck|uv|gpg|docker)
                    brew_missing+=("$dep")
                    ;;
                "docker-upgrade")
                    echo -e "  ${RED}•${NC} Docker: brew upgrade --cask docker-desktop (requires version 28+)"
                    ;;
                "brew")
                    echo -e "  ${RED}•${NC} Homebrew: /bin/bash -c \"\$($SECURE_CURL -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                    ;;
                "gopls")
                    echo -e "  ${RED}•${NC} gopls: go install golang.org/x/tools/gopls@latest"
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

        # All Brewfile-managed tools: one pointer to the command that installs them.
        if [ ${#brew_missing[@]} -ne 0 ]; then
            echo -e "  ${RED}•${NC} Homebrew packages (${brew_missing[*]}):"
            echo -e "      run ${GREEN}./dotfiles.sh install${NC}  (installs the Brewfile via brew bundle)"
        fi
        echo ""
        echo -e "${YELLOW}Install missing dependencies and try again.${NC}"
        exit 1
    fi

    # Additional setup instructions
    echo -e "${BLUE}💡 After installing dependencies, recommended setup:${NC}"
    echo -e "  ${BLUE}•${NC} Install Node.js: nvm install --lts && nvm use --lts"
    echo ""
}

install_brew_packages() {
    local brewfile="$DOTFILES_DIR/Brewfile"

    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}⚠️  Homebrew not found; skipping brew packages.${NC}"
        echo -e "  ${BLUE}•${NC} Install Homebrew first, then re-run: $0 install"
        return 1
    fi

    if [[ ! -f "$brewfile" ]]; then
        echo -e "${RED}❌ Brewfile not found at $brewfile${NC}"
        return 1
    fi

    echo -e "${BLUE}📦 Installing Homebrew packages from Brewfile...${NC}"
    # brew bundle is idempotent: it installs anything missing and is a no-op otherwise.
    if brew bundle --file="$brewfile"; then
        echo -e "${GREEN}✅ Homebrew packages are up to date${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ Some Homebrew packages failed to install${NC}"
        echo ""
        return 1
    fi
}

detect_ssh_keys() {
    echo -e "${BLUE}🔍 Scanning for SSH keys...${NC}"

    local ssh_keys=()
    for key in ~/.ssh/id_*; do
        # Check if file exists and is not a .pub file
        if [ -f "$key" ] && [ "$key" = "${key%.pub}" ]; then
            ssh_keys+=("$key")
        fi
    done

    if [ ${#ssh_keys[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No SSH private keys found in ~/.ssh/${NC}"
        echo -e "${BLUE}💡 Generate keys with: ssh-keygen -t ed25519 -C 'your_email@example.com'${NC}"
        echo ""
        return 1
    fi

    # Check for existing SSH key selections in machine.config
    local xdg_config="$(get_xdg_config_dir)"
    local ssh_config="$xdg_config/ssh/machine.config"
    local cached_keys=()
    local cached_selection=""
    local key_path

    if [[ -f "$ssh_config" ]] && [[ -s "$ssh_config" ]]; then
        # Parse existing keys from machine.config
        # Temporarily disable nounset for regex matching
        set +u
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi

            if [[ "$line" =~ IdentityFile[[:space:]]+(.*) ]]; then
                # Capture BASH_REMATCH immediately
                local matched_path="${BASH_REMATCH[1]}"
                # Expand HOME references
                matched_path="${matched_path/#\~/$HOME}"
                matched_path="${matched_path//\$HOME/$HOME}"
                cached_keys+=("$matched_path")
            fi
        done < "$ssh_config"
        # Re-enable nounset
        set -u

        # Build cached selection string for display
        if [[ ${#cached_keys[@]} -eq ${#ssh_keys[@]} ]]; then
            cached_selection="all"
        elif [[ ${#cached_keys[@]} -gt 0 ]]; then
            # Find indices of cached keys
            local indices=()
            for cached in "${cached_keys[@]}"; do
                local idx=1
                for key in "${ssh_keys[@]}"; do
                    if [[ "$key" == "$cached" ]]; then
                        indices+=("$idx")
                        break
                    fi
                    ((idx++))
                done
            done
            cached_selection=$(IFS=,; echo "${indices[*]}")
        fi
    fi

    echo -e "${GREEN}Found SSH keys:${NC}"
    local i=1
    for key in "${ssh_keys[@]}"; do
        echo -e "  ${GREEN}$i.${NC} $key"
        ((i++))
    done

    echo ""
    echo "Select keys to auto-load on shell startup:"
    echo "  - Enter numbers comma-separated (e.g., 1,3)"
    echo "  - Enter 'all' for all keys"
    echo "  - Enter 'none' to skip SSH key setup"

    local selection=""
    # If not in a terminal (non-interactive) and we have cached selection, use it
    if ! tty -s && [[ -n "$cached_selection" ]]; then
        echo -e "${BLUE}📋 Using existing SSH key selection (non-interactive mode): $cached_selection${NC}"
        selection="$cached_selection"
    else
        if [[ -n "$cached_selection" ]]; then
            printf "Selection [%s]: " "$cached_selection"
        else
            printf "Selection: "
        fi
        read -r selection < /dev/tty
        # Use cached value if Enter pressed
        selection="${selection:-$cached_selection}"
    fi

    local selected_keys=()
    if [[ "$selection" == "all" ]]; then
        selected_keys=("${ssh_keys[@]}")
    elif [[ "$selection" == "none" ]]; then
        return 1
    else
        # Split comma-separated values using zsh array splitting
        local indices_array=(${(s:,:)selection})
        for index in "${indices_array[@]}"; do
            # Trim leading/trailing whitespace
            index=$(echo "$index" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 1 ] && [ "$index" -le ${#ssh_keys[@]} ]; then
                local selected_key="${ssh_keys[$index]}"
                selected_keys+=("$selected_key")
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

    # Initialize variables to avoid 'parameter not set' error with set -u
    local git_name=""
    local git_email=""

    # Check if git user is already configured (including machine.config via include)
    local existing_name=$(git config user.name 2>/dev/null || echo "")
    local existing_email=$(git config user.email 2>/dev/null || echo "")

    # Prompt with defaults - allow Enter to accept cached values
    # If not in a terminal (non-interactive) and we have existing config, use it
    if ! tty -s && [[ -n "$existing_name" ]] && [[ -n "$existing_email" ]]; then
        echo -e "${BLUE}📋 Using existing Git configuration (non-interactive mode)${NC}"
        git_name="$existing_name"
        git_email="$existing_email"
    else
        if [[ -n "$existing_name" ]]; then
            printf "Enter your full name for Git commits [%s]: " "$existing_name"
        else
            printf "Enter your full name for Git commits: "
        fi
        read -r git_name < /dev/tty
        # Use existing value if Enter pressed
        git_name="${git_name:-$existing_name}"

        if [[ -n "$existing_email" ]]; then
            printf "Enter your email address for Git commits [%s]: " "$existing_email"
        else
            printf "Enter your email address for Git commits: "
        fi
        read -r git_email < /dev/tty
        # Use existing value if Enter pressed
        git_email="${git_email:-$existing_email}"
    fi

    if [[ -z "${git_name:-}" || -z "${git_email:-}" ]]; then
        echo -e "${YELLOW}⚠️  Name and email are required for Git${NC}"
        return 1
    fi

    GIT_USER_NAME="$git_name"
    GIT_USER_EMAIL="$git_email"

    if [[ "$git_name" == "$existing_name" && "$git_email" == "$existing_email" ]]; then
        echo -e "${GREEN}✅ Keeping existing Git config: $git_name <$git_email>${NC}"
    else
        echo -e "${GREEN}✅ Git user configured: $git_name <$git_email>${NC}"
    fi
    return 0
}

detect_gpg_keys() {
    echo -e "${BLUE}🔍 Scanning for GPG keys...${NC}"

    # Commit signing is required (commit.gpgsign = true), so a key is mandatory.
    # This function MUST end with GPG_SELECTED_KEY set, or return non-zero so the
    # caller halts install — it can never leave signing unconfigured.

    # Check if gpg is available
    if ! command -v gpg &> /dev/null; then
        echo -e "${RED}❌ GPG not found, but commit signing is required.${NC}"
        echo -e "${BLUE}💡 Install it (brew install gnupg), then re-run install.${NC}"
        return 1
    fi

    local gpg_keys=($(gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep '^sec' | awk '{print $2}' | cut -d'/' -f2))

    if [ ${#gpg_keys[@]} -eq 0 ]; then
        echo -e "${RED}❌ No GPG private keys found, but commit signing is required.${NC}"
        echo -e "${BLUE}💡 Generate one: gpg --full-generate-key   (then re-run ./dotfiles.sh install)${NC}"
        echo ""
        return 1
    fi

    # Pick a sensible default key (used for auto-select and as the prompt default):
    #   1) the key already configured (cached, via git config), else
    #   2) a key whose UID matches the configured git email, else
    #   3) the first key.
    local default_idx=""
    local existing_key=$(git config user.signingkey 2>/dev/null || echo "")
    local idx=1
    for key in "${gpg_keys[@]}"; do
        if [[ -n "$existing_key" && "$key" == "$existing_key" ]]; then
            default_idx="$idx"; break
        fi
        ((idx++))
    done
    if [[ -z "$default_idx" && -n "${GIT_USER_EMAIL:-}" ]]; then
        idx=1
        for key in "${gpg_keys[@]}"; do
            if gpg --list-keys "$key" 2>/dev/null | grep -qi "<$GIT_USER_EMAIL>"; then
                default_idx="$idx"; break
            fi
            ((idx++))
        done
    fi
    [[ -z "$default_idx" ]] && default_idx=1

    # Exactly one key: auto-select it. No prompt, nothing to skip.
    if [ ${#gpg_keys[@]} -eq 1 ]; then
        GPG_SELECTED_KEY="${gpg_keys[1]}"
        echo -e "${GREEN}✅ Using the only GPG key found: $GPG_SELECTED_KEY${NC}"
        return 0
    fi

    # Multiple keys: show them and choose. We always end with a valid key.
    echo -e "${GREEN}Found GPG keys:${NC}"
    local i=1
    for key in "${gpg_keys[@]}"; do
        local key_info=$(gpg --list-keys "$key" 2>/dev/null | grep uid | head -1 | sed 's/uid.*] //')
        echo -e "  ${GREEN}$i.${NC} $key - $key_info"
        ((i++))
    done
    echo ""

    # Non-interactive: take the computed default (cached/email/first), never empty.
    if ! tty -s; then
        GPG_SELECTED_KEY="${gpg_keys[$default_idx]}"
        echo -e "${BLUE}📋 Non-interactive: selected key #$default_idx ($GPG_SELECTED_KEY)${NC}"
        return 0
    fi

    # Interactive: loop until a valid number is entered. Enter accepts the default.
    # There is intentionally no "none" option — signing is required.
    local selection=""
    while true; do
        printf "Select a key for commit signing [%s]: " "$default_idx"
        read -r selection < /dev/tty
        selection="${selection:-$default_idx}"
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#gpg_keys[@]} ]; then
            GPG_SELECTED_KEY="${gpg_keys[$selection]}"
            echo -e "${GREEN}✅ Selected key: $GPG_SELECTED_KEY${NC}"
            return 0
        fi
        echo -e "${YELLOW}⚠️  Enter a number between 1 and ${#gpg_keys[@]}.${NC}"
    done
}

configure_machine_keys() {
    local machine_id="$(hostname -s)"
    local xdg_config="$(get_xdg_config_dir)"

    echo -e "${BLUE}⚙️  Configuring keys for machine: $machine_id${NC}"

    # Create XDG config directories with secure permissions
    mkdir -p "$xdg_config/git" && chmod 700 "$xdg_config/git"
    mkdir -p "$xdg_config/ssh" && chmod 700 "$xdg_config/ssh"
    mkdir -p "$xdg_config/gpg" && chmod 700 "$xdg_config/gpg"
    mkdir -p ~/.ssh/sockets && chmod 700 ~/.ssh/sockets  # For SSH connection multiplexing

    # Configure Git machine-specific settings
    local git_config="$xdg_config/git/machine.config"
    touch "$git_config"
    chmod 600 "$git_config"
    echo "# Machine-specific Git configuration for: $machine_id" > "$git_config"
    echo "# Generated by dotfiles on $(date)" >> "$git_config"
    echo "" >> "$git_config"

    # User name and email (required)
    if [[ -n "$GIT_USER_NAME" && -n "$GIT_USER_EMAIL" ]]; then
        echo "[user]" >> "$git_config"
        echo "    name = $GIT_USER_NAME" >> "$git_config"
        echo "    email = $GIT_USER_EMAIL" >> "$git_config"

        # Signing key — install guarantees one is set (see detect_gpg_keys).
        echo "    signingkey = $GPG_SELECTED_KEY" >> "$git_config"

        echo -e "${GREEN}✅ Git user and signing configuration saved${NC}"
    else
        echo -e "${RED}❌ Git user configuration missing${NC}"
    fi

    # Generate complete GPG config (GPG doesn't support includes)
    # Use shared template and add machine-specific settings
    local gpg_main_config="$HOME/.gnupg/gpg.conf"
    local gpg_template="$DOTFILES_DIR/gnupg/gpg.conf"

    if [[ -f "$gpg_template" ]]; then
        # Ensure .gnupg directory exists with correct permissions
        mkdir -p "$HOME/.gnupg"
        chmod 700 "$HOME/.gnupg"

        # Remove any existing gpg.conf (could be symlink or file)
        rm -f "$gpg_main_config"

        # Copy shared template to main GPG config
        cp "$gpg_template" "$gpg_main_config"
        chmod 600 "$gpg_main_config"

        # Append machine-specific settings
        echo "" >> "$gpg_main_config"
        echo "# === MACHINE-SPECIFIC CONFIG ===" >> "$gpg_main_config"
        echo "# Generated by dotfiles on $(date) for: $machine_id" >> "$gpg_main_config"

        # install guarantees a key is set (see detect_gpg_keys).
        echo "default-key $GPG_SELECTED_KEY" >> "$gpg_main_config"
        echo -e "${GREEN}✅ GPG configuration generated with key: $GPG_SELECTED_KEY${NC}"

        echo "# === END MACHINE-SPECIFIC CONFIG ===" >> "$gpg_main_config"

        # Generate gpg-agent.conf with dynamic pinentry detection
        local agent_config="$HOME/.gnupg/gpg-agent.conf"
        touch "$agent_config"
        chmod 600 "$agent_config"

        # Detect best available pinentry program
        local pinentry_program=""
        for program in pinentry-curses pinentry-tty pinentry; do
            if command -v "$program" &>/dev/null; then
                pinentry_program=$(command -v "$program")
                break
            fi
        done

        # Generate agent configuration
        cat > "$agent_config" << EOF
# GPG Agent configuration for tmux compatibility
# Generated by dotfiles on $(date) for: $machine_id

EOF

        # Add pinentry program if found
        if [[ -n "$pinentry_program" ]]; then
            echo "# Use detected pinentry program" >> "$agent_config"
            echo "pinentry-program $pinentry_program" >> "$agent_config"
        else
            echo "# Using system default pinentry" >> "$agent_config"
        fi

        # Add remaining configuration
        cat >> "$agent_config" << 'EOF'

# Cache settings (8 hours default, 24 hours max)
default-cache-ttl 28800
max-cache-ttl 86400

# Enable SSH support (allows using GPG keys for SSH)
enable-ssh-support

# Security settings
no-allow-external-cache
EOF

        echo -e "${GREEN}✅ GPG agent configuration generated with pinentry: ${pinentry_program:-system default}${NC}"
    else
        echo -e "${YELLOW}⚠️  GPG template not found, skipping GPG configuration${NC}"
    fi

    # Configure SSH machine-specific settings
    local ssh_config="$xdg_config/ssh/machine.config"
    touch "$ssh_config"
    chmod 600 "$ssh_config"
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
        echo "    UseKeychain yes" >> "$ssh_config"
        echo "    AddKeysToAgent yes" >> "$ssh_config"
        echo "" >> "$ssh_config"
        echo -e "${GREEN}✅ SSH key configuration saved${NC}"

        # Add encrypted keys to keychain
        echo ""
        echo -e "${BLUE}🔐 Setting up SSH keychain integration...${NC}"
        for key in "${SSH_SELECTED_KEYS[@]}"; do
            if is_ssh_key_encrypted "$key"; then
                add_ssh_key_to_keychain "$key" || true
            else
                echo "⚠️  Key $(basename "$key") is not encrypted, keychain not needed"
            fi
        done
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

    local new_hostname=""
    # If not in a terminal (non-interactive), keep current hostname
    if ! tty -s; then
        echo -e "${BLUE}📋 Keeping current hostname (non-interactive mode): $current_hostname${NC}"
        return 0
    fi

    printf "Enter new hostname (or press Enter to keep current): "
    read -r new_hostname < /dev/tty

    if [[ -z "${new_hostname:-}" ]]; then
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
    local skip_dep_check="${1:-false}"

    echo -e "${GREEN}🏠 Installing dotfiles...${NC}"

    if [[ "$skip_dep_check" != "true" ]]; then
        # Install brew packages first so the dependency check below passes.
        install_brew_packages
        check_dependencies
    fi

    echo -e "${BLUE}📁 Using dotfiles directory: $DOTFILES_DIR${NC}"

    # Change to dotfiles directory
    cd "$DOTFILES_DIR"

    # Use stow to link each package directory
    echo -e "${YELLOW}🔗 Stowing all dotfiles...${NC}"
    for entry in "${PACKAGES[@]}"; do
        # Parse package:target format
        if [[ "$entry" == *":"* ]]; then
            package="${entry%:*}"
            target="${entry#*:}"
            # Safe variable expansion in target path
            target="${target/#\~/$HOME}"
            target="${target//\$HOME/$HOME}"
            target="${target//\$XDG_CONFIG_DIR/$XDG_CONFIG_DIR}"
        else
            package="$entry"
            target="$HOME"
        fi

        if [ -d "$package" ]; then
            echo "   Stowing $package to $target..."
            mkdir -p "$target"
            stow --restow --target="$target" "$package"
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

    # Detect and configure GPG keys. Commit signing is required (commit.gpgsign = true),
    # so install MUST NOT proceed without a key — that would write a config that breaks
    # every commit. Halt and tell the user how to fix it instead.
    if detect_gpg_keys; then
        echo -e "${GREEN}✅ GPG key selected${NC}"
    else
        echo -e "${RED}❌ A GPG signing key is required but none was configured.${NC}"
        echo -e "${BLUE}💡 Create/import a key, then re-run: ./dotfiles.sh install${NC}"
        return 1
    fi

    echo ""

    # Configure machine-specific settings
    configure_machine_keys

    echo ""

    # Configure hostname
    configure_hostname

    # Install Tmux Plugin Manager (TPM) for session persistence
    echo ""
    source "$DOTFILES_DIR/shell/tmux.sh"
    install_tmux_plugins

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

    # Remove SSH keys from keychain before unstowing
    echo -e "${BLUE}🔐 Removing SSH keys from macOS Keychain...${NC}"
    local xdg_config="$(get_xdg_config_dir)"
    if [[ -f "$xdg_config/ssh/machine.config" ]]; then
        grep "IdentityFile" "$xdg_config/ssh/machine.config" | while read -r line; do
            local key_path=$(echo "$line" | awk '{print $2}' | sed "s|~|$HOME|")
            if [[ -f "$key_path" ]]; then
                remove_ssh_key_from_keychain "$key_path" || true
            fi
        done
    else
        echo "⚠️  No SSH configuration found, skipping keychain cleanup"
    fi
    echo ""

    # Change to dotfiles directory
    cd "$DOTFILES_DIR"

    # Unstow all packages
    echo -e "${YELLOW}🔗 Unstowing all dotfiles...${NC}"
    for entry in "${PACKAGES[@]}"; do
        # Parse package:target format
        if [[ "$entry" == *":"* ]]; then
            package="${entry%:*}"
            target="${entry#*:}"
            # Safe variable expansion in target path
            target="${target/#\~/$HOME}"
            target="${target//\$HOME/$HOME}"
            target="${target//\$XDG_CONFIG_DIR/$XDG_CONFIG_DIR}"
        else
            package="$entry"
            target="$HOME"
        fi

        if [ -d "$package" ]; then
            echo "   Unstowing $package from $target..."
            # Only unstow if target directory exists
            if [ -d "$target" ]; then
                stow --delete --target="$target" "$package" &>/dev/null || true
            else
                echo "      (target directory doesn't exist, skipping)"
            fi
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
    # Status function needs different error handling than installation
    # Save current settings and switch to compatible mode
    local saved_options="$-"
    set +euo pipefail
    trap - ERR

    # Set up environment variables the same way .zshrc does
    export XDG_CONFIG_DIR="$(get_xdg_config_dir)"
    export SHELL_DIR="$DOTFILES_DIR/shell"

    # Load NVM if not already available and cache the result
    if [[ "${DOTFILES_NVM_LOADED:-}" != "1" ]]; then
        if command -v nvm &>/dev/null; then
            export DOTFILES_NVM_LOADED=1
        elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
            export NVM_DIR="$HOME/.nvm"
            source "$NVM_DIR/nvm.sh" &>/dev/null
            export DOTFILES_NVM_LOADED=1
        fi
    fi

    # Load language modules to ensure correct PATH setup (especially for uv-managed Python)
    if [[ -f "$DOTFILES_DIR/shell/languages.sh" ]]; then
        source "$DOTFILES_DIR/shell/languages.sh" &>/dev/null || true
    fi

    # Validate key security if not already done in this session
    if [[ "${DOTFILES_KEY_SECURITY_VALIDATED:-}" != "1" ]]; then
        source "$DOTFILES_DIR/shell/security.sh"
        if validate_key_security; then
            export DOTFILES_KEY_SECURITY_VALIDATED=1
        fi
    fi

    # Source the shell functions to get access to dotfiles_status
    source "$DOTFILES_DIR/shell/functions.sh"

    # Call the unified status function
    dotfiles_status

    echo ""
}

update_environment() {
    echo -e "${GREEN}🔄 Updating Development Environment...${NC}"

    # Set update mode for modules to install global packages
    export DOTFILES_UPDATE_MODE=1

    # Check and install brew-based tools
    echo -e "${BLUE}🍺 Checking Homebrew tools...${NC}"

    # Install anything declared in the Brewfile that's missing.
    install_brew_packages

    # Check for just
    local JUST_VERSION=$(get_version_requirement "just")
    if [[ -n "$JUST_VERSION" ]]; then
        if ! command -v just &> /dev/null; then
            echo -e "${YELLOW}⚠️  just not found, installing...${NC}"
            if command -v brew &> /dev/null; then
                brew install just
                echo -e "${GREEN}✅ just installed successfully!${NC}"
            else
                echo -e "${RED}❌ Homebrew not found. Cannot install just.${NC}"
            fi
        else
            local installed_just_version=$(just --version 2>/dev/null | awk '{print $2}' | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            echo -e "${GREEN}✅ just $installed_just_version is already installed${NC}"

            # Check if upgrade is available
            local brew_outdated=$(brew outdated just 2>/dev/null)
            if [[ -n "$brew_outdated" ]]; then
                echo -e "${BLUE}📦 Upgrading just...${NC}"
                brew upgrade just
                echo -e "${GREEN}✅ just upgraded successfully!${NC}"
            fi
        fi
    fi

    # Check for duckdb
    local DUCKDB_VERSION=$(get_version_requirement "duckdb")
    if [[ -n "$DUCKDB_VERSION" ]]; then
        if ! command -v duckdb &> /dev/null; then
            echo -e "${YELLOW}⚠️  duckdb not found, installing...${NC}"
            if command -v brew &> /dev/null; then
                brew install duckdb
                echo -e "${GREEN}✅ duckdb installed successfully!${NC}"
            else
                echo -e "${RED}❌ Homebrew not found. Cannot install duckdb.${NC}"
            fi
        else
            local installed_duckdb_version=$(duckdb --version 2>/dev/null | awk '{print $1}' | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            echo -e "${GREEN}✅ duckdb $installed_duckdb_version is already installed${NC}"

            # Check if upgrade is available
            local brew_outdated=$(brew outdated duckdb 2>/dev/null)
            if [[ -n "$brew_outdated" ]]; then
                echo -e "${BLUE}📦 Upgrading duckdb...${NC}"
                brew upgrade duckdb
                echo -e "${GREEN}✅ duckdb upgraded successfully!${NC}"
            fi
        fi
    fi

    echo ""

    # Update Node.js via NVM
    local NODE_VERSION=$(get_version_requirement "node")
    if [[ -n "$NODE_VERSION" ]]; then
        # Ensure NVM is loaded
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            source "$NVM_DIR/nvm.sh"

            echo -e "${BLUE}📦 Installing Node.js $NODE_VERSION...${NC}"
            nvm install "$NODE_VERSION"

            echo -e "${BLUE}🔧 Setting Node.js $NODE_VERSION as default...${NC}"
            nvm alias default "$NODE_VERSION"

            # Install global npm packages
            echo -e "${BLUE}📦 Installing global npm packages...${NC}"
            if [[ -f "$DOTFILES_DIR/npm-globals/package.json" ]]; then
                # Load utility functions for npm globals installation
                source "$DOTFILES_DIR/shell/utils.sh"
                install_npm_globals "$DOTFILES_DIR/npm-globals/package.json"
            fi

            echo -e "${GREEN}✅ Node.js environment updated!${NC}"
        else
            echo -e "${RED}❌ NVM not found. Please install NVM first.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Node.js version not specified in versions.config${NC}"
    fi

    echo ""

    # Update Go via GVM
    local GO_VERSION=$(get_version_requirement "go")
    if [[ -n "$GO_VERSION" ]]; then
        # Check if GVM is available
        if [[ -s "$HOME/.gvm/scripts/gvm" ]]; then
            # Temporarily disable strict mode for GVM compatibility
            local saved_errexit="" saved_nounset="" saved_pipefail=""
            [[ $- == *e* ]] && saved_errexit="e"
            [[ $- == *u* ]] && saved_nounset="u"
            [[ $- == *o* ]] && saved_pipefail="o pipefail"
            set +euo pipefail
            trap - ERR

            # Source GVM once at the beginning to set up all functions and environment
            source "$HOME/.gvm/scripts/gvm"

            echo -e "${BLUE}📦 Installing Go $GO_VERSION...${NC}"
            if gvm install "$GO_VERSION" --binary || gvm list | grep -q "$GO_VERSION"; then
                # Check if version is already the default
                if gvm list | grep -q "=> $GO_VERSION"; then
                    echo -e "${GREEN}✅ Go $GO_VERSION is already active and set as default${NC}"
                else
                    echo -e "${BLUE}🔧 Setting Go $GO_VERSION as default...${NC}"
                    if gvm use "$GO_VERSION" --default; then
                        echo -e "${GREEN}✅ Go environment updated!${NC}"
                    else
                        echo -e "${RED}❌ Failed to set Go $GO_VERSION as default${NC}"
                        # Restore strict mode and error trap before returning
                        [[ -n "$saved_errexit" ]] && set -e
                        [[ -n "$saved_nounset" ]] && set -u
                        [[ -n "$saved_pipefail" ]] && set -o pipefail
                        trap 'echo "❌ Installation failed at line $LINENO" >&2; exit 1' ERR
                        return 1
                    fi
                fi
            else
                echo -e "${RED}❌ Failed to install Go $GO_VERSION${NC}"
                # Restore strict mode and error trap before returning
                [[ -n "$saved_errexit" ]] && set -e
                [[ -n "$saved_nounset" ]] && set -u
                [[ -n "$saved_pipefail" ]] && set -o pipefail
                trap 'echo "❌ Installation failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
                return 1
            fi

            # Restore strict mode and error trap
            [[ -n "$saved_errexit" ]] && set -e
            [[ -n "$saved_nounset" ]] && set -u
            [[ -n "$saved_pipefail" ]] && set -o pipefail
            trap 'echo "❌ Installation failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
        else
            echo -e "${RED}❌ GVM not found. Please install GVM first.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Go version not specified in versions.config${NC}"
    fi

    echo ""

    # Update/Install gopls (Go language server)
    local GOPLS_VERSION=$(get_version_requirement "gopls")
    if [[ -n "$GOPLS_VERSION" ]]; then
        if command -v go &> /dev/null; then
            if command -v gopls &> /dev/null; then
                local installed_gopls_version=$(gopls version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 | sed 's/v//')
                echo -e "${GREEN}✅ gopls $installed_gopls_version is already installed${NC}"
                echo -e "${BLUE}📦 Updating gopls to latest version...${NC}"
                go install golang.org/x/tools/gopls@latest
                echo -e "${GREEN}✅ gopls updated successfully!${NC}"
            else
                echo -e "${YELLOW}⚠️  gopls not found, installing...${NC}"
                go install golang.org/x/tools/gopls@latest
                echo -e "${GREEN}✅ gopls installed successfully!${NC}"
            fi
        else
            echo -e "${RED}❌ Go not found. Cannot install gopls.${NC}"
            echo -e "${BLUE}💡 Install Go first using: ./dotfiles.sh update${NC}"
        fi
    fi

    echo ""

    # Update/Install uv
    local UV_VERSION=$(get_version_requirement "uv")
    if [[ -n "$UV_VERSION" ]]; then
        if command -v uv &> /dev/null; then
            local installed_uv_version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
            if [[ "$installed_uv_version" != "unknown" ]]; then
                echo -e "${BLUE}📦 uv $installed_uv_version is already installed${NC}"
                echo -e "${BLUE}💡 To update uv, run: brew upgrade uv${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  uv not found${NC}"
            echo -e "${BLUE}💡 Install with: brew install uv  (or ./dotfiles.sh update)${NC}"
        fi
    fi

    echo ""

    # Update/Install Python via uv
    local PYTHON_VERSION=$(get_version_requirement "python")
    if [[ -n "$PYTHON_VERSION" ]]; then
        if command -v uv &> /dev/null; then
            echo -e "${BLUE}📦 Checking Python $PYTHON_VERSION via uv...${NC}"

            # Check if Python version is already installed via uv
            if uv python list 2>/dev/null | grep -q "cpython-$PYTHON_VERSION"; then
                echo -e "${GREEN}✅ Python $PYTHON_VERSION is already installed via uv${NC}"
            else
                echo -e "${BLUE}📦 Installing Python $PYTHON_VERSION via uv...${NC}"
                if uv python install "$PYTHON_VERSION"; then
                    echo -e "${GREEN}✅ Python $PYTHON_VERSION installed successfully!${NC}"
                else
                    echo -e "${RED}❌ Failed to install Python $PYTHON_VERSION${NC}"
                fi
            fi

            # Show all installed Python versions
            echo -e "${BLUE}📋 Installed Python versions:${NC}"
            uv python list 2>/dev/null || echo "  No Python versions found"
        else
            echo -e "${RED}❌ uv not found. Cannot manage Python versions.${NC}"
            echo -e "${BLUE}💡 Install uv first: brew install uv  (or ./dotfiles.sh update)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Python version not specified in versions.config${NC}"
    fi

    echo ""

    # Update tmux plugins
    source "$DOTFILES_DIR/shell/tmux.sh"
    update_tmux_plugins

    echo ""

    echo ""

    # Show SSH and security status
    echo -e "${BLUE}🔐 Security Status:${NC}"

    # SSH Agent Status
    if [[ -n "$SSH_AUTH_SOCK" ]] && ssh-add -l &>/dev/null; then
        local key_count=$(ssh-add -l 2>/dev/null | wc -l | xargs)
        echo -e "   ✅ SSH Agent: Running ($key_count keys loaded)"
    else
        echo -e "   ⚠️  SSH Agent: Not running or no keys loaded"
        echo -e "       💡 Load SSH keys: ssh-add ~/.ssh/id_ed25519"
    fi

    # GPG Agent Status
    if pgrep -x "gpg-agent" > /dev/null && gpg-connect-agent --quiet /bye &>/dev/null; then
        echo -e "   ✅ GPG Agent: Running"
    else
        echo -e "   ⚠️  GPG Agent: Not running"
    fi

    # GitHub SSH Connectivity
    if ssh -T git@github.com -o ConnectTimeout=5 -o BatchMode=yes 2>&1 | grep -q "successfully authenticated"; then
        echo -e "   ✅ GitHub SSH: Connected"
    else
        echo -e "   ⚠️  GitHub SSH: Connection failed"
        echo -e "       💡 Test with: ssh -T git@github.com"
    fi

    echo ""

    # Clean up update mode
    unset DOTFILES_UPDATE_MODE
}

# Record a tool:version pin in versions.config (replace existing line or append).
set_version_pin() {
    local tool="$1" ver="$2"
    local versions_file="$DOTFILES_DIR/versions.config"
    [[ -z "$ver" ]] && return 0
    # Escape sed metacharacters defensively (tool/ver come from a fixed list, but never
    # feed unescaped data into a sed pattern/replacement).
    local tool_re ver_rep
    tool_re=$(printf '%s' "$tool" | sed 's/[.[*^$/]/\\&/g')
    ver_rep=$(printf '%s' "$ver" | sed 's/[&/|]/\\&/g')
    if grep -qE "^${tool}:" "$versions_file" 2>/dev/null; then
        sed -i '' "s|^${tool_re}:.*|${tool}:${ver_rep}|" "$versions_file"
    else
        printf '%s:%s\n' "$tool" "$ver" >> "$versions_file"
    fi
    echo -e "  ${BLUE}📌${NC} versions.config: ${tool} → ${ver}"
}

# Upgrade everything to the latest available versions AND record the new versions in
# versions.config. Contrast with `update`, which converges TO the pinned versions.
# Best-effort: strict mode is relaxed so one failing step doesn't abort the rest.
upgrade_environment() {
    echo -e "${GREEN}⬆️  Upgrading everything to latest...${NC}"
    echo ""

    # Relax strict mode + ERR trap for the duration (restored at the end).
    set +e +u +o pipefail
    trap - ERR

    # --- Homebrew: install missing Brewfile packages, then upgrade everything ---
    if command -v brew &> /dev/null; then
        echo -e "${BLUE}🍺 Homebrew: installing Brewfile + upgrading all packages...${NC}"
        install_brew_packages
        brew update && brew upgrade
    else
        echo -e "${YELLOW}⚠️  Homebrew not found; skipping${NC}"
    fi
    echo ""

    # --- Rust toolchains ---
    if command -v rustup &> /dev/null; then
        echo -e "${BLUE}🦀 Updating Rust toolchains...${NC}"
        rustup update
    fi
    echo ""

    # --- Node: latest LTS via nvm ---
    local nvm_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
    if [[ -s "$nvm_dir/nvm.sh" ]]; then
        echo -e "${BLUE}📦 Node: installing latest LTS...${NC}"
        export NVM_DIR="$nvm_dir"
        source "$nvm_dir/nvm.sh"
        if nvm install --lts; then
            nvm alias default 'lts/*' >/dev/null 2>&1
            set_version_pin node "$(nvm version 'lts/*' 2>/dev/null)"   # e.g. v22.11.0
        fi
    fi
    echo ""

    # --- Go: latest stable via gvm ---
    if [[ -s "$HOME/.gvm/scripts/gvm" ]]; then
        echo -e "${BLUE}📦 Go: installing latest stable...${NC}"
        source "$HOME/.gvm/scripts/gvm"
        local go_latest
        # Filter pre-release/release.* LINES first, then extract — otherwise a regex
        # like go1.27rc1 gets truncated to go1.27 (a nonexistent release) and slips past.
        go_latest="$(gvm listall 2>/dev/null | grep -vE 'beta|rc|release\.' | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | sort -V | tail -1)"
        if [[ -n "$go_latest" ]] && gvm install "$go_latest" --binary; then
            gvm use "$go_latest" --default >/dev/null 2>&1
            set_version_pin go "$go_latest"
        else
            echo -e "  ${YELLOW}⚠️  Could not determine/install latest Go${NC}"
        fi
    fi
    echo ""

    # --- gopls: latest (tracks the Go toolchain) ---
    if command -v go &> /dev/null; then
        echo -e "${BLUE}📦 gopls: installing latest...${NC}"
        if go install golang.org/x/tools/gopls@latest; then
            set_version_pin gopls "$(gopls version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/v//')"
        fi
    fi
    echo ""

    # --- Python: latest stable minor via uv (+ record uv's own version) ---
    if command -v uv &> /dev/null; then
        echo -e "${BLUE}🐍 Python: installing latest stable via uv...${NC}"
        local py_latest
        # Only stable cpython: a release is "cpython-3.14.6-" (trailing dash), whereas
        # pre-releases are "cpython-3.15.0b3-" and variants are "cpython-3.14.6+freethreaded".
        # Requiring the dash right after the patch number excludes both.
        py_latest="$(uv python list 2>/dev/null | grep -oE 'cpython-3\.[0-9]+\.[0-9]+-' | grep -oE '3\.[0-9]+' | sort -V -u | tail -1)"
        if [[ -n "$py_latest" ]] && uv python install "$py_latest"; then
            set_version_pin python "$py_latest"
        fi
        set_version_pin uv "$(uv --version 2>/dev/null | awk '{print $2}')"
    fi
    echo ""

    # --- Homebrew tool floors: record the now-installed versions ---
    echo -e "${BLUE}📌 Recording installed Homebrew tool versions...${NC}"
    local t ver
    for t in git zsh stow brew just docker nvim tmux tig starship jq rg luarocks gpg duckdb jj gh delta; do
        grep -qE "^${t}:" "$DOTFILES_DIR/versions.config" 2>/dev/null || continue
        command -v "$t" &> /dev/null || continue
        case "$t" in
            just|duckdb) ver="$($t --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" ;;
            tmux)        ver="$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)" ;;
            brew)        ver="$(brew --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)" ;;
            nvim)        ver="$(nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)" ;;
            zsh|stow|git|docker) ver="$($t --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)" ;;
            *)           ver="$($t --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)" ;;
        esac
        set_version_pin "$t" "$ver"
    done
    echo ""

    # --- Neovim plugins (treesitter stays commit-pinned) ---
    if command -v nvim &> /dev/null; then
        echo -e "${BLUE}📦 Neovim: updating plugins (:Lazy update)...${NC}"
        nvim --headless "+Lazy! update" +qa 2>&1 | tail -3
    fi
    echo ""

    # Restore strict mode + ERR trap (the script always runs with these on).
    set -euo pipefail
    trap 'echo "❌ Installation failed at line $LINENO" >&2; exit 1' ERR

    echo -e "${GREEN}✅ Upgrade complete.${NC}"
    echo -e "${BLUE}💡 Review the new pins before committing:${NC} git diff versions.config nvim/lazy-lock.json"
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
        # Install brew packages first so the dependency check below passes.
        install_brew_packages
        # Enable auto-install for reinstall to avoid blocking on gopls/uv
        check_dependencies true
        if [[ $? -ne 0 ]]; then
            exit 1
        fi
        install_dotfiles true  # Skip dependency check since we just did it
        ;;
    "status")
        show_status
        ;;
    "update")
        update_environment
        ;;
    "upgrade")
        upgrade_environment
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
