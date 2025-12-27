# Dotfiles Architecture

This document outlines the high-level design principles and organizational structure of this dotfiles repository following Agent Rules specification.

**📋 Agent Rules Compliance**: This file follows Agent Rules specification using imperative statements with RFC 2119 keywords (MUST, SHOULD, MAY, NEVER) and flat bullet list format for AI coding agents.

For detailed architecture of specific components, see the `AGENTS.md` files in each directory.

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
- Version compliance checking validates tool security

### 5. **Developer Experience First**
- Single command installation: `./dotfiles.sh install`
- Interactive setup with clear guidance  
- Fail fast with helpful error messages
- Re-runnable installation for reconfiguration

## High-Level Architecture

```
dotfiles/                           # Git repository (shareable)
├── shell/                          # Zsh configuration
│   └── AGENTS.md                    # Shell architecture documentation
├── git/                           # Base Git config + includes
│   └── AGENTS.md                   # Git architecture documentation
├── ssh/                           # Base SSH config + includes
│   └── AGENTS.md                   # SSH architecture documentation
├── tmux/                          # Terminal multiplexer
│   └── AGENTS.md                   # Tmux architecture documentation
├── nvim/                          # Neovim configuration
│   └── AGENTS.md                   # Neovim architecture documentation
├── misc/                          # Starship prompt, colors
├── claude_hooks/                  # Claude Code integration hooks
│   ├── bin/                       # Compiled hook binaries
│   ├── hooks/                     # Individual hook source code  
│   │   └── whitespace-cleaner/    # Whitespace cleanup hook
│   └── build-hooks.sh             # Hook build script
├── packages.config                # Package list for GNU Stow
├── versions.config                # Centralized version requirements
├── dotfiles.sh                    # Installation & management script
├── ARCHITECTURE.md                # This file - high-level architecture
├── README.md                      # User documentation
└── CLAUDE.md                      # AI agent development guidelines

~/.config/                         # XDG user configs (machine-specific)
├── git/machine.config             # Git user & signing keys
├── ssh/machine.config             # SSH identity files
└── [other tool configs]           # Tool-specific machine configs
```

## Key Components

### Configuration Management System
- **`packages.config`** - Single source of truth for all packages managed by GNU Stow
- **`versions.config`** - Centralized minimum version requirements for all tools
- **GNU Stow** - Symlink management for installation and status validation
- **XDG directories** - Machine-specific configuration storage

### Version Management
All tool version requirements are centralized in `versions.config`:
- **Status checking**: `./dotfiles.sh status` validates all tools meet minimum versions
- **Automatic updates**: `./dotfiles.sh update` installs/updates language versions  
- **Team consistency**: Requirements shared via git, ensuring consistent environments
- **Flexible comparison**: Handles version prefixes (v24.1.0, go1.24.1) properly

### Security Architecture
- **GPG signing required**: All commits and tags must be signed
- **Modern cryptography**: SSH and curl use current best practices
- **Permission validation**: Automatic checking of file permissions for security-sensitive files
- **Machine isolation**: Personal data never committed to shared repository

## Package System

### Configuration-Driven Approach
The dotfiles system uses a **configuration-driven package approach**:

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
```

## Directory-Specific Architecture

Each major component has detailed architecture documentation in its respective `AGENTS.md` file:

### 📁 **[shell/AGENTS.md](shell/AGENTS.md)**
- Modular Zsh configuration system
- Performance-optimized shell startup
- Version manager integration (NVM, GVM, Rustup)
- Security validation and agent management

### 📁 **[nvim/AGENTS.md](nvim/AGENTS.md)**  
- Lazy-loaded plugin architecture
- Language Server Protocol integration
- Modular configuration with graceful degradation
- Plugin management with version locking

### 📁 **[git/AGENTS.md](git/AGENTS.md)**
- Layered configuration using native Git includes
- Machine-specific user information management
- Required GPG signing enforcement
- Multi-machine identity separation

### 📁 **[ssh/AGENTS.md](ssh/AGENTS.md)**
- Modern SSH security configuration
- Connection multiplexing and optimization
- Machine-specific identity file management
- Secure defaults and cryptographic settings

### 📁 **[tmux/AGENTS.md](tmux/AGENTS.md)**
- Development-focused terminal multiplexer setup
- Vi-style key bindings and navigation
- Visual enhancements and status line configuration
- Integration with development workflows

## Installation and Management

### Dependency Management
The installer validates and guides installation of all required tools:
- **Core tools**: `stow`, `starship`, `git`, `zsh`, `luarocks`, `rg`, `brew`
- **Containerization**: `docker` (version 28+)
- **Editors**: `nvim`, `tmux`, `tig`
- **Version managers**: `nvm`, `gvm`, `rustup`
- **Security tools**: `gpg`

### Machine Configuration Process
1. **Interactive Git User Setup**: Prompts for name and email
2. **SSH Key Detection**: Scans `~/.ssh/` and allows selection
3. **GPG Key Detection**: Scans GPG keyring and allows selection
4. **Config Generation**: Creates machine-specific include files
5. **Version Validation**: Ensures all tools meet minimum requirements

### Management Commands
```bash
./dotfiles.sh install      # Install/configure dotfiles (interactive)
./dotfiles.sh status       # Check installation status and version compliance
./dotfiles.sh update       # Update Node.js, Go versions from versions.config
./dotfiles.sh uninstall    # Remove all dotfiles symlinks  
./dotfiles.sh help         # Show all available commands
```

## Development Guidelines

### Architecture Documentation Maintenance
Each component directory contains an `AGENTS.md` file with detailed architecture documentation:

- MUST update `AGENTS.md` when making changes to that component
- MUST include code examples and configuration patterns
- MUST document why certain architectural choices were made
- MUST document how the component integrates with others
- MUST follow Agent Rules specification format

### Adding New Components
- MUST create package directory with configuration files
- MUST add to `packages.config` with appropriate target
- MUST create `AGENTS.md` documenting the component's architecture following Agent Rules format
- SHOULD update version requirements in `versions.config` if needed
- MUST test installation and status checking

### Modifying Existing Components
- MUST update the component files and configuration
- MUST update `AGENTS.md` to reflect architectural changes
- MUST update version requirements if dependencies change
- MUST test compatibility across different environments
- MUST update integration points in other components if needed

## Why This Architecture?

### Problems Solved
- **Monolithic configurations**: Separated into focused, modular components
- **Personal data leakage**: Clean separation between shared and private config
- **Manual dependency management**: Automated validation and installation guidance
- **Inconsistent environments**: Centralized version requirements and validation
- **Documentation drift**: Distributed architecture documentation stays current

### Benefits Achieved
- **Maintainable**: Each component documented and architected independently
- **Secure**: Personal data never committed, security enforced by default
- **Consistent**: Version requirements ensure identical environments
- **Performant**: Optimized for fast startup and efficient operation
- **Extensible**: Easy to add new tools and configurations

### Real-World Examples

**Multi-Machine Developer Scenario:**
```
Work Laptop:
- Git: work-email@company.com + work GPG key
- SSH: Work GitHub/GitLab keys + VPN keys
- Same editor, shell, and tool configurations

Personal Laptop:
- Git: personal@gmail.com + personal GPG key  
- SSH: Personal GitHub keys + server keys
- Identical tool configurations and versions
```

This architecture demonstrates how proper separation of concerns, distributed documentation, and configuration-driven management create a robust, maintainable system that scales from individual use to team adoption while maintaining security and performance.

For detailed information about any specific component, refer to the `AGENTS.md` file in that component's directory.