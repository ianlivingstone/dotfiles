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
    "nvim"      # Neovim editor configuration
)
```

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

**❌ Traditional Approach Issues:**
- Hardcoded personal information in git
- Manual key management in shell scripts
- Inconsistent configuration across machines  
- Complex shell startup with key loading loops

**✅ Our Solution Benefits:**
- Clean git repository with no personal data
- Native tool configuration (faster, more reliable)
- Machine-specific configs in proper XDG locations
- Fast shell startup with lazy configuration loading

### Development Workflow

**Adding New Configuration:**
1. Add base/shared config to appropriate package directory
2. Use native tool includes for machine-specific parts
3. Update installer if new dependencies required
4. Test on multiple machines to ensure portability

**Machine Setup:**
1. Clone repository: `git clone <repo> ~/.dotfiles`
2. Run installer: `cd ~/.dotfiles && ./dotfiles.sh install`
3. Follow interactive prompts for machine-specific setup
4. Restart shell or source configuration

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
- Package system allows easy addition of new tools
- Include system supports conditional configuration
- XDG compliance ensures forward compatibility

### Maintenance
- Single source of truth for shared configuration
- Machine-specific configs easily regenerated
- Clear separation makes debugging straightforward

This architecture balances security, maintainability, and user experience while following established conventions and best practices.