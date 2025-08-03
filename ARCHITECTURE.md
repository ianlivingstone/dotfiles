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

## Package Structure

Each directory in the repository represents a "package" that can be installed via GNU Stow:

```bash
PACKAGES=(
    "shell"     # Zsh configuration and aliases
    "git"       # Git configuration with includes  
    "ssh"       # SSH configuration with includes
    "tmux"      # Terminal multiplexer setup
    "misc"      # Starship prompt, dircolors
    "nvim"      # Neovim editor configuration (modular)
)
```

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
- **Lazy Loading**: Plugins load only when needed (performance)
- **Self-Contained**: Each plugin file is independent and shareable
- **Clean Bootstrap**: Works perfectly on fresh installations
- **Easy Debugging**: Know exactly which file contains what functionality

## Installation Process

### Dependency Management
The installer checks for and guides installation of:

**Required Dependencies** (installation blocked if missing):
- Core tools: `stow`, `starship`, `git`, `zsh`, `luarocks`, `rg`, `brew`
- Editors: `nvim`, `tmux`  
- Version managers: `nvm`, `gvm`, `cargo/rust`

**Security Enforcement**:
- All curl commands use `--proto '=https' --tlsv1.2`
- GPG signing required for all Git operations
- SSH keys properly configured per machine

### Machine Configuration Setup
1. **Interactive Git User Setup**: Prompts for name and email
2. **SSH Key Detection**: Scans `~/.ssh/` and allows selection
3. **GPG Key Detection**: Scans GPG keyring and allows selection
4. **Config Generation**: Creates machine-specific include files

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