# Dotfiles Architecture

This document outlines the design principles, architecture decisions, and organizational structure of this dotfiles repository.

## Design Principles

### 1. **Clean Separation of Concerns**
- **Shared Configuration**: Common settings that work across all machines (in git repository)
- **Machine-Specific Configuration**: Personal data like names, emails, keys (in XDG directories)
- **Never mix**: Sensitive or machine-specific data never enters the git repository

### 2. **XDG Base Directory Compliance**
- Machine-specific configs stored in `${XDG_CONFIG_HOME:-$HOME/.config}/`
- Respects user's XDG environment variables
- Never overrides system XDG settings

### 3. **Native Tool Configuration**
- Use Git's native `[include]` for layered configuration
- Use SSH's native `Include` for layered configuration  
- Avoid shell scripting where native tools provide better solutions

### 4. **Security by Default**
- All Git commits and tags require GPG signing
- All SSH connections use secure defaults
- All curl commands enforce HTTPS-only with TLS 1.2+

### 5. **Developer Experience First**
- Single command installation: `./dotfiles.sh install`
- Interactive setup with clear guidance  
- Fail fast with helpful error messages
- Re-runnable installation for reconfiguration

## Architecture Overview

```
dotfiles/                           # Git repository (shareable)
├── shell/                          # Zsh configuration
├── git/                           # Base Git config + includes
├── ssh/                           # Base SSH config + includes
├── tmux/                          # Terminal multiplexer
├── nvim/                          # Neovim configuration
├── misc/                          # Starship prompt, colors
└── dotfiles.sh                    # Installation & management

~/.config/                         # XDG user configs (machine-specific)
├── git/machine.config             # Git user & signing keys
└── ssh/machine.config             # SSH identity files
```

## Configuration Layering

### Git Configuration Flow
```bash
# ~/.gitconfig (from dotfiles/git/.gitconfig)
[include]
    path = ~/.config/git/machine.config
[commit]
    gpgsign = true    # Required for all machines

# ~/.config/git/machine.config (generated per machine)
[user]
    name = Your Name
    email = work@company.com        # Different per machine
    signingkey = ABC123DEF456       # Different key per machine
```

### SSH Configuration Flow
```bash
# ~/.ssh/config (from dotfiles/ssh/.ssh/config)
Include ~/.config/ssh/machine.config
Host *
    ServerAliveInterval 60          # Common settings

# ~/.config/ssh/machine.config (generated per machine)
Host *
    IdentityFile ~/.ssh/id_work     # Different keys per machine
    IdentitiesOnly yes
```

## Package Management System

### Core Architecture

The dotfiles system uses a **configuration-driven package approach** with these key components:

1. **`packages.config`** - Single source of truth for all packages
2. **Package directories** - Self-contained tool configurations  
3. **GNU Stow** - Symlink management for installation
4. **Stow-based validation** - Status checking using Stow's own logic

### Package Configuration Format

```bash
# packages.config
# Format: package[:target]
# Variables are expanded during installation

zsh                                    # Default target: ~/
git                                    # Default target: ~/
ssh                                    # Default target: ~/
tmux                                   # Default target: ~/
misc                                   # Default target: ~/
nvim:$XDG_CONFIG_DIR/nvim             # Custom target: ~/.config/nvim/
gnupg:$HOME/.gnupg                    # Custom target: ~/.gnupg/
```

**Key Features**:
- **Single source of truth**: All packages defined once
- **Variable expansion**: Supports `$HOME`, `$XDG_CONFIG_DIR`, etc.
- **Flexible targets**: Each package can go anywhere
- **Comment support**: Lines starting with `#` are ignored

### Package Directory Structure

Each package directory contains the files to be linked:

```bash
# For default target (~/):
git/
├── .gitconfig                        # → ~/.gitconfig
└── .gitignore_global                 # → ~/.gitignore_global

# For custom targets:
nvim/                                 # Target: ~/.config/nvim/
├── init.lua                          # → ~/.config/nvim/init.lua  
├── lazy-lock.json                    # → ~/.config/nvim/lazy-lock.json
└── lua/                              # → ~/.config/nvim/lua/

gnupg/                                # Target: ~/.gnupg/
├── gpg.conf                          # → ~/.gnupg/gpg.conf
└── gpg-agent.conf                    # → ~/.gnupg/gpg-agent.conf
```

### Adding New Packages

**1. Create package directory and files**:
```bash
mkdir myapp
echo "config content" > myapp/config.toml

# For files going to ~/.config/myapp/:
mkdir -p myapp-config
echo "config content" > myapp-config/settings.json
```

**2. Add to packages.config**:
```bash
# Default target (~/):
echo "myapp" >> packages.config

# Custom target:  
echo "myapp-config:\$XDG_CONFIG_DIR/myapp" >> packages.config
```

**3. Test and install**:
```bash
./dotfiles.sh status     # Should show new packages  
./dotfiles.sh reinstall  # Install new packages
```

### Removing Packages

**1. Remove from packages.config**:
```bash
# Edit packages.config and delete the package line
vim packages.config
```

**2. Uninstall**:
```bash
./dotfiles.sh reinstall  # Removes old packages, installs remaining ones
```

**3. Optionally delete package directory**:
```bash
rm -rf myapp/  # Only if you don't want it available anymore
```

### Status Validation System

The status system uses **Stow's own logic** for validation instead of duplicating assumptions:

```bash
check_package_status() {
    local package="$1" target="$2"
    
    # Ask Stow: "What would you do if you were to restow this package?"
    stow_output=$(stow --no --verbose --restow --target="$target" "$package" 2>&1)
    exit_code=$?
    
    # Interpret Stow's response:
    if [[ $exit_code -eq 0 && -z "$stow_output" ]]; then
        echo "✅ $package → properly stowed to $target"
    else
        echo "❌ $package → needs attention: $stow_output"  
    fi
}
```

**Benefits of Stow-based validation**:
- **No logic duplication**: Uses Stow's own understanding of linking
- **Handles edge cases**: Stow knows about conflicts, existing files, etc.
- **Self-healing hints**: Shows exactly what Stow would do to fix issues
- **Works with any target**: Respects custom targets automatically

### Package System Benefits

**Before (hardcoded arrays)**:
```bash
# dotfiles.sh
PACKAGES=("zsh" "git" "ssh" "tmux" "misc" "nvim")

# functions.sh  
packages=("shell" "git" "ssh" "nvim" "tmux" "misc")  # ❌ Out of sync!

# Status checking
case "$package" in
    "nvim")
        if [[ -L ~/.config/nvim ]]; then
            echo "✅ linked"
        elif [[ -d ~/.config/nvim ]]; then
            echo "❌ directory exists"     # ❌ Assumes how Stow works
        fi
        ;;
esac
```

**After (configuration-driven)**:
```bash
# packages.config (single source of truth)
nvim:$XDG_CONFIG_DIR/nvim

# Both dotfiles.sh and functions.sh read the same config
while read -r line; do
    check_package_status "$line" "$dotfiles_dir"  # ✅ Uses Stow's logic
done < packages.config
```

**Key Improvements**:
- ✅ **Single source of truth**: One config file drives everything
- ✅ **No duplication**: Package list defined once, used everywhere  
- ✅ **Stow validation**: Status uses Stow's actual logic, not assumptions
- ✅ **Flexible targets**: Easy to add packages with custom locations
- ✅ **Zero maintenance**: Add package once, works in install/status/uninstall

### Neovim Modular Architecture

The Neovim package follows a sophisticated modular design that exemplifies our architectural principles:

```
nvim/.config/nvim/
├── init.lua                    # Minimal entry point (12 lines)
└── lua/
    ├── config/
    │   ├── options.lua        # Vim settings (no dependencies)
    │   ├── keymaps.lua        # Global keymaps (no dependencies)
    │   ├── autocmds.lua       # File-specific autocommands
    │   └── lazy-bootstrap.lua # Plugin manager installation
    └── plugins/
        ├── init.lua           # Main plugin loader & orchestrator
        ├── colorscheme.lua    # Theme configuration
        ├── completion.lua     # Autocompletion system
        ├── lsp.lua           # Language Server Protocol
        ├── telescope.lua     # Fuzzy finder
        ├── treesitter.lua    # Syntax highlighting
        ├── editor.lua        # File explorer & editor enhancements
        ├── ui.lua           # Status line & UI components
        └── coding.lua       # Coding utilities
```

**Why This Structure?**

**Problem Solved**: The original `init.lua` was a 446-line monolithic file mixing bootstrap code, settings, plugin configurations, and autocommands. This violated multiple design principles:
- **Single Responsibility**: One file doing everything
- **Fail Fast**: Plugin failures could break entire config
- **Maintainability**: Hard to debug or modify specific features
- **Fresh Installation**: Couldn't bootstrap from scratch reliably

**Solution Benefits**:
- **Graceful Degradation**: Each module handles missing dependencies safely
- **Fast Startup**: Core functionality loads first, optional features later
- **Easy Debugging**: Each module can be disabled independently
- **Clean Dependencies**: Clear separation between config and plugins

### Shell Module Architecture

The shell package follows the same modular design principles as Neovim, providing a clean and maintainable Zsh configuration:

```
shell/
├── .zshrc              # Minimal entry point & module loader
├── utils.sh            # Shared utility functions
├── core.sh             # PATH, completion, basic settings
├── aliases.sh          # Command aliases
├── languages.sh        # Programming language environments
├── functions.sh        # Utility functions & status reporting
├── security.sh         # Security validation
├── agents.sh           # SSH and GPG agent management
├── prompt.sh           # Shell prompt configuration
├── nvm.sh              # Node.js version management module
└── gvm.sh              # Go version management module
```

**Module Loading Order** (critical for dependencies):
1. **`utils.sh`** - Utility functions (path resolution, config loading)
2. **`core.sh`** - Basic shell setup (PATH, completion)
3. **`aliases.sh`** - Command shortcuts
4. **`languages.sh`** - Programming environments (NVM, GVM, Rust)
5. **`functions.sh`** - Status reporting and utility functions
6. **`security.sh`** - Key validation and security checks
7. **`agents.sh`** - SSH/GPG agent management
8. **`prompt.sh`** - Shell prompt and status display

**Key Design Features**:

- **Centralized Utilities**: `utils.sh` provides shared functions:
  - `get_shell_dir()` - Portable path resolution with symlink support
  - `load_config()` - Config file loading with fallbacks
  - `add_to_path()` - Safe PATH management with deduplication
  - `show_warning()` - Consistent warning message format

- **Version Manager Modules**: Dedicated modules for each language:
  - **Fast filesystem checks** instead of slow manager commands
  - **Centralized configuration** in `versions.config`
  - **Unified update system** via `dotfiles update`
  - **Proper PATH management** ensuring binaries are available

- **Performance Optimized**:
  - **No expensive operations** during shell startup
  - **Warnings-only approach** for missing versions
  - **Filesystem-based checks** for version detection
  - **Lazy loading** where possible

**Module Dependencies**:
- All modules use `get_shell_dir()` for portable path resolution
- Language modules use `load_config()`, `add_to_path()`, `show_warning()`
- Functions module displays status using same utility patterns

**Benefits of This Architecture**:
- **DRY Principle**: No code duplication across modules
- **Consistent Behavior**: All modules follow same patterns
- **Easy Maintenance**: Fix bugs once in utils.sh
- **Performance**: Fast startup with filesystem-based checks
- **Portability**: Works across different environments and installation paths

### Shell Module Development Guidelines

When creating new shell modules, follow these established patterns:

**1. Path Resolution**:
```bash
# ✅ ALWAYS use the utility function
MODULE_DIR="$(get_shell_dir)"

# ❌ NEVER hardcode paths
MODULE_DIR="/Users/user/dotfiles/shell"  # Bad!
```

**2. Version Requirements**:
```bash
# ✅ Use centralized version management
TOOL_VERSION=$(get_version_requirement "tool" || echo "default-version")

# ❌ Don't use separate config files
load_config "$MODULE_DIR/tool.config" "TOOL_VERSION" "default-version"  # Old pattern
```

**3. PATH Management**:
```bash
# ✅ Use safe PATH addition
add_to_path "/path/to/tool/bin"

# ❌ Don't manually manage PATH
export PATH="/path/to/tool/bin:$PATH"  # Bad - can cause duplicates
```

**4. Warning Messages**:
```bash
# ✅ Use consistent warning format
show_warning "Tool $VERSION not installed"

# ❌ Don't hardcode warning messages
echo "⚠️  Tool not found. Run dotfiles update"  # Bad - inconsistent
```

**5. Module Structure Template**:
```bash
#!/usr/bin/env zsh
# Tool Name setup and configuration

# Get module directory
MODULE_DIR="$(get_shell_dir)"

# Get version requirement from versions.config
TOOL_VERSION=$(get_version_requirement "tool" || echo "default-version")

# Check if tool manager exists
if [[ -s "$HOME/.tool/scripts/tool" ]]; then
    source "$HOME/.tool/scripts/tool"
    
    # Fast filesystem checks
    if [[ ! -d "$HOME/.tool/versions/$TOOL_VERSION" ]]; then
        show_warning "Tool $TOOL_VERSION not installed"
    fi
    
    # Use configured version and manage PATH
    if [[ -d "$HOME/.tool/versions/$TOOL_VERSION" ]]; then
        tool use "$TOOL_VERSION" > /dev/null 2>&1 || true
        add_to_path "$HOME/.tool/versions/$TOOL_VERSION/bin"
    fi
else
    echo "❌ Tool not found. Install with: [installation command]"
fi
```

## Installation Process

### Dependency Management
The installer checks for and guides installation of:

**Required Dependencies** (installation blocked if missing):
- Core tools: `stow`, `starship`, `git`, `zsh`, `luarocks`, `rg`, `brew`
- Containerization: `docker` (version 28+)
- Editors: `nvim`, `tmux`  
- Version managers: `nvm`, `gvm`, `rustup`

**Security Enforcement**:
- All curl commands use `--proto '=https' --tlsv1.2`
- GPG signing required for all Git operations
- SSH keys properly configured per machine

### Machine Configuration Setup
1. **Interactive Git User Setup**: Prompts for name and email
2. **SSH Key Detection**: Scans `~/.ssh/` and allows selection
3. **GPG Key Detection**: Scans GPG keyring and allows selection
4. **Config Generation**: Creates machine-specific include files

### Version Management System

All tool version requirements are centralized in `versions.config`:

```bash
# Core system tools (required)
git:2.40
docker:28.0
nvim:0.9

# Programming languages (required)  
node:v24.1.0
go:go1.24.1

# Development managers (required)
nvm:0.39
gvm:1.0
rustup:1.25
```

**Version Validation Process**:
1. **Status checking**: `./dotfiles.sh status` validates all installed tools against minimum versions
2. **Automatic updates**: `./dotfiles.sh update` installs/updates Node.js and Go to specified versions  
3. **Shell modules**: Use `get_version_requirement()` to read centralized requirements
4. **Team consistency**: Requirements shared via git, ensuring consistent environments

**Version Comparison Features**:
- **Prefix handling**: Properly compares `v24.1.0` vs `24.1.0`, `go1.24.1` vs `1.24.1`
- **Semantic versioning**: Uses `sort -V` for proper version comparison
- **Clear reporting**: Shows current vs required versions for non-compliant tools

## Why This Architecture?

### Problems Solved

**❌ Traditional Dotfiles Issues:**
- **Monolithic configurations**: Single massive files mixing concerns
- **Hardcoded personal information**: Personal data committed to git
- **Manual dependency management**: Shell scripts for key/environment setup
- **Inconsistent behavior**: Different configs per machine with manual syncing
- **Fragile installations**: One failure breaks everything
- **Poor performance**: Heavy shell startup loading everything upfront

**✅ Our Solution Benefits:**
- **Clean separation**: Shared vs machine-specific configurations
- **Native tool support**: Git `[include]`, SSH `Include`, lazy.nvim modules
- **Graceful degradation**: Components fail independently without breaking others
- **Performance optimization**: Lazy loading and minimal shell overhead
- **Security by default**: GPG signing required, HTTPS-only, proper key isolation
- **XDG compliance**: Standard directory structures and user customization

### Development Workflow

**Adding New Configuration:**
1. **Dotfiles packages**: Add base/shared config to appropriate package directory
2. **Machine-specific**: Use native tool includes for personal data
3. **Dependencies**: Update installer if new tools required
4. **Testing**: Verify on multiple machines for portability

**Adding New Neovim Plugin:**
1. **Create module**: Add new `.lua` file in `plugins/` directory
2. **Self-contained**: Include graceful loading checks and error handling
3. **Lazy loading**: Use appropriate triggers (`ft`, `cmd`, `keys`, `event`)
4. **Integration**: Add to plugin loader in `plugins/init.lua`

**Machine Setup:**
1. Clone repository: `git clone <repo> ~/.dotfiles`
2. Run installer: `cd ~/.dotfiles && ./dotfiles.sh install`
3. Follow interactive prompts for machine-specific setup
4. Restart shell or source configuration

**Neovim Fresh Installation:**
1. Delete plugin cache: `rm -rf ~/.local/share/nvim/`
2. Start Neovim: `nvim`
3. Lazy.nvim auto-bootstraps and installs all plugins
4. LSP servers install automatically via Mason

## Security Considerations

### Private Data Isolation
- SSH private keys: Stay in `~/.ssh/` (never copied)
- GPG private keys: Stay in GPG keyring (never copied)  
- Personal emails: Only in machine-specific configs
- Signing keys: Only key IDs stored, not key material

### Network Security
- All downloads use HTTPS with TLS 1.2+
- Package manager installations prefer official sources
- No automatic script execution without user consent

### Access Control
- Machine configs readable only by user (`600` permissions)
- SSH socket directory properly secured
- GPG agent properly isolated per session

## Future Considerations

### Extensibility
- **Package system**: Easy addition of new tools via stow packages
- **Include system**: Supports conditional and machine-specific configuration
- **Plugin modularity**: Neovim plugins can be added/removed independently
- **XDG compliance**: Forward compatibility with evolving standards

### Maintenance
- **Single source of truth**: Shared configuration in one place
- **Machine-specific regeneration**: Easy to recreate personal configs
- **Clear debugging**: Modular structure isolates issues quickly
- **Performance monitoring**: Each component can be profiled independently

### Real-World Examples

**Multi-Machine Developer Scenario:**
```
Work Laptop:
- Git: work-email@company.com + work GPG key
- SSH: Work GitHub/GitLab keys + VPN keys
- Neovim: Same editor experience across machines

Personal Laptop:
- Git: personal@gmail.com + personal GPG key  
- SSH: Personal GitHub keys + server keys
- Neovim: Identical configuration, different LSP projects
```

**Team Sharing:**
- **Fork repository**: Remove personal data, keep shared configs
- **Selective sharing**: Share specific plugin configurations
- **Corporate compliance**: Machine-specific configs stay local
- **Onboarding**: New team members get consistent tooling

This architecture demonstrates how proper separation of concerns, native tool support, and graceful error handling create a robust, maintainable system that scales from individual use to team adoption while maintaining security and performance.