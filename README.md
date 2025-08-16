# Ian Livingstone's Dotfiles

Modern, secure dotfiles with machine-specific configuration support. Built for developers who work across multiple machines with different identities and keys.

## ✨ What You Get

### 🚀 **Modern Development Environment**
- **Zsh** with Starship prompt showing git status, language versions, and system info
- **Neovim** with LSP, autocompletion, fuzzy finding, and syntax highlighting
- **Tmux** for terminal multiplexing and session management
- **Git** with security-first configuration and helpful aliases

### 🔒 **Security by Default**
- **GPG signing** required for all commits and tags
- **SSH key management** with proper per-machine configuration
- **HTTPS-only** curl commands with modern TLS requirements
- **Automatic security validation** warns about improper file permissions on shell startup
- **Secure file permissions** (600/700) enforced for all configuration files
- **Version compliance checking** validates all tools meet minimum requirements

### 🖥️ **Multi-Machine Support**
- **Different Git identities** per machine (work email vs personal email)
- **Different SSH keys** per machine (work keys vs personal keys)  
- **Different GPG keys** per machine for commit signing
- **Clean separation** between shared config and personal data

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/ianlivingstone/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Run the installer (handles everything!)
./dotfiles.sh install

# 3. Restart your shell
exec zsh
```

The installer will:
- ✅ Check for required dependencies and show install commands if missing
- ✅ Prompt for your Git name and email for this machine
- ✅ Detect and let you select SSH keys to use
- ✅ Detect and let you select a GPG key for commit signing
- ✅ Configure everything automatically

## 🔧 Dependencies

The installer checks for these and provides install commands if missing:

**Required Tools:**
```bash
brew install stow starship luarocks ripgrep neovim tmux
brew install --cask docker
```

**Development Managers:**
```bash
# Node.js version manager (NVM)
curl --proto '=https' --tlsv1.2 -o- -sSfL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Go version manager (GVM) 
curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash

# Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## 📋 Version Management

All tool versions are centrally managed in `versions.config`:

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

- **Status checking**: `./dotfiles.sh status` validates all tools meet minimum versions
- **Automatic updates**: `./dotfiles.sh update` installs/updates Node.js and Go to specified versions
- **Team consistency**: Version requirements are shared across all machines via git

## 🛠️ Management Commands

```bash
./dotfiles.sh install      # Install/configure dotfiles (interactive)
./dotfiles.sh status       # Check installation status and version compliance
./dotfiles.sh update       # Update Node.js, Go versions from versions.config
./dotfiles.sh uninstall    # Remove all dotfiles symlinks  
./dotfiles.sh help         # Show all available commands
```

### 📦 **Neovim Plugin Management**

This setup uses [lazy.nvim](https://lazy.folke.io/) with controlled updates:

```vim
" In Neovim - check plugin status and updates
:Lazy                      " Open plugin manager UI
:Lazy sync                 " Update plugins and lockfile
:Lazy update               " Update plugins only
:Lazy clean                " Remove unused plugins
```

**How it works:**
- Plugins are locked to specific versions via `lazy-lock.json`
- When you modify plugin config, lazy.nvim **notifies** you but **doesn't auto-update**
- You control when to update with `:Lazy sync` (recommended) or `:Lazy update`
- The lockfile is committed to git, ensuring consistent plugin versions across machines

## 📁 What Gets Installed

- **Shell configuration** → `~/.zshrc`, `~/.zprofile`
- **Git configuration** → `~/.gitconfig` (with machine-specific includes)
- **SSH configuration** → `~/.ssh/config` (with machine-specific includes)
- **Tmux configuration** → `~/.tmux.conf`
- **Neovim configuration** → `~/.config/nvim/`
- **Starship prompt** → `~/.config/starship.toml`

**Machine-specific configs** are stored in `~/.config/git/` and `~/.config/ssh/` (never in git repo).

## 🎯 Key Features

### 📊 **Smart Shell Status**
Every new shell shows a one-line summary:
```
🏠 user@hostname ~/directory | ⏱ uptime | 📦 git-branch ✓ | 🕐 time
```

### 🎨 **Intelligent Prompt** 
- **Language versions** automatically displayed (Node.js, Go, Python, Rust, Java)
- **Git status** with clean indicators (✓ clean, ± dirty, ⇡ ahead)
- **Context awareness** for Docker, Kubernetes, AWS when relevant

### ⚡ **Powerful Editor**
- **LSP integration** for TypeScript, Go, Python, and more
- **Fuzzy finding** for files, text search, and buffers (`<Space>ff`, `<Space>fg`)
- **Smart autocompletion** with context-aware suggestions
- **Auto-formatting** and import organization on save
- **Controlled plugin updates** - notifies when config changes, manual update with `:Lazy sync`

### 🔐 **Security & Identity Management**
- **Per-machine Git identities** (different name/email per machine)
- **Per-machine SSH keys** (work keys vs personal keys)
- **Required GPG signing** for all commits and tags
- **Secure defaults** for all network operations

## 🏗️ Architecture

This dotfiles system uses a **layered configuration approach**:

- **Base configurations** live in this git repository (shareable settings)
- **Machine-specific data** lives in `~/.config/` (private, never in git)
- **Native tool includes** handle the layering (Git `[include]`, SSH `Include`)

For detailed information about the design principles and architecture decisions, see [ARCHITECTURE.md](ARCHITECTURE.md).

## 🤝 Customization & Package Management

### 📦 Adding New Packages

To add a new package (e.g., `vscode`):

1. **Create package directory**:
   ```bash
   mkdir vscode
   ```

2. **Add configuration files**:
   ```bash
   # For files that go to ~/
   echo "config content" > vscode/settings.json
   
   # For files that go to ~/.config/vscode/
   mkdir -p vscode/.config/vscode
   echo "config content" > vscode/.config/vscode/settings.json
   ```

3. **Add to packages.config**:
   ```bash
   # Add at the end of packages.config
   echo "vscode" >> packages.config
   
   # Or for custom target location:
   echo "vscode:$XDG_CONFIG_DIR/vscode" >> packages.config
   ```

4. **Test installation**:
   ```bash
   ./dotfiles.sh status    # Should show new package
   ./dotfiles.sh reinstall # Install new package
   ```

### 🗑️ Removing Packages

To remove a package (e.g., `tmux`):

1. **Remove from packages.config**:
   ```bash
   # Edit packages.config and delete the line containing "tmux"
   vim packages.config
   ```

2. **Uninstall and reinstall**:
   ```bash
   ./dotfiles.sh reinstall  # Removes old packages, installs current ones
   ```

3. **Optionally delete package directory**:
   ```bash
   rm -rf tmux/  # Only if you don't want it available
   ```

### 🎯 Package Targets

The `packages.config` format supports custom targets:

```bash
# Default target (~/):
git
ssh
tmux

# Custom targets:
nvim:$XDG_CONFIG_DIR/nvim           # Goes to ~/.config/nvim/
gnupg:$HOME/.gnupg                  # Goes to ~/.gnupg/
myapp:$HOME/.local/share/myapp      # Goes to ~/.local/share/myapp/
```

**Variables available**:
- `$HOME` - Your home directory
- `$XDG_CONFIG_DIR` - Usually `~/.config`
- Any other environment variables

### 🔧 Status Checking

The status command automatically validates all packages using Stow's own logic:
```bash
./dotfiles.sh status
# ✅ git → properly stowed to /Users/ian
# ❌ nvim → would make changes: LINK: init.lua
# ⚠️  missing → package directory not found
```

This ensures the status reflects exactly what Stow would do, with no guesswork.

**Key Benefits**:
- **Single source of truth**: All packages defined in `packages.config`
- **Stow-validated**: Status uses Stow's own validation logic  
- **Flexible targets**: Each package can go to a different location
- **Zero duplication**: Add once in config, works everywhere

The separation between shared and machine-specific configuration means you can safely share your fork while keeping personal data private.