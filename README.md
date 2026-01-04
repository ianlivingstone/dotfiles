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
brew install stow starship luarocks ripgrep neovim tmux tig
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

Your tool versions are automatically managed and validated:

```bash
./dotfiles.sh status    # Check if all tools meet requirements
./dotfiles.sh update    # Update Node.js and Go to latest specified versions
```

**What this gives you:**
- Automatic validation that you have the right tool versions
- One command to update Node.js and Go across all machines
- Consistent development environment with your team
- Clear warnings if any tool is outdated

Version requirements are defined in `versions.config` and shared across all machines.

## 🛠️ Management Commands

```bash
./dotfiles.sh install      # Install/configure dotfiles (interactive)
./dotfiles.sh status       # Check installation status and version compliance
./dotfiles.sh update       # Update Node.js, Go versions from versions.config
./dotfiles.sh uninstall    # Remove all dotfiles symlinks  
./dotfiles.sh help         # Show all available commands
```

### 📦 **Plugin Management**

#### **Neovim Plugins**
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

#### **Claude Code Integration**
Seamless integration with Claude Code AI assistant using [claude-code.nvim](https://github.com/greggh/claude-code.nvim):

```bash
# Start Claude Code from within Neovim
:ClaudeCode                # Open Claude Code terminal
:ClaudeCodeToggle          # Toggle Claude Code window
:ClaudeCodeContinue        # Continue previous conversation
:ClaudeCodeResume          # Resume with conversation history

# File explorer integration
<Space>e                   # Toggle file explorer (nvim-tree)
```

**Features:**
- **Automatic file reload**: Files modified by Claude Code are automatically reloaded
- **Terminal integration**: Claude Code runs in a dedicated terminal window
- **Git integration**: Detects project root and maintains context
- **Conversation management**: Continue and resume previous Claude Code sessions
- **Window management**: Configurable split positioning and sizing

#### **Tmux Session Persistence**
Sessions automatically save/restore using tmux-resurrect and tmux-continuum:

```bash
# Session management (in tmux)
Ctrl-a Ctrl-s             # Save session manually
Ctrl-a Ctrl-r             # Restore session manually

# Plugin management
./dotfiles.sh update       # Update tmux plugins to latest versions
```

**How it works:**
- **Auto-save**: Sessions save every 15 minutes automatically
- **Auto-restore**: Sessions restore when tmux starts
- **Pane contents**: Terminal output is preserved across restarts
- **Persistence**: Survives computer restarts and tmux crashes

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

## 🤝 Customization

Want to add your own tools to this dotfiles system?

1. Create a directory with your config files
2. Add the directory name to `packages.config`
3. Run `./dotfiles.sh reinstall`

**Example - Adding VSCode configs:**
```bash
mkdir vscode
# Add your config files to the vscode/ directory
echo "vscode" >> packages.config
./dotfiles.sh reinstall
```

That's it! Your configs are now managed alongside everything else.

For advanced customization and package management details, see [CLAUDE.md](CLAUDE.md) and [ARCHITECTURE.md](ARCHITECTURE.md).

## 🛠️ Development Tools

### 🔗 **Claude Code Integration**
Custom Rust hooks automatically enhance your workflow with whitespace cleanup, formatting, and code quality improvements.

The separation between shared and machine-specific configuration means you can safely share your fork while keeping personal data private.
