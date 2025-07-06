# Ian Livingstone's Dotfiles

My personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) for easy installation and organization.

## Features

- **Shell**: Zsh configuration with Starship prompt and startup status message
- **Git**: Git configuration and aliases
- **Neovim**: Modern Neovim configuration with LSP, autocompletion, and file navigation
- **Tmux**: Terminal multiplexer setup with focus events
- **Starship**: Custom prompt with language detection and clean git status
- **Status Message**: One-line system info displayed on shell startup
- **Misc**: Additional tools and color schemes

## Requirements

- **macOS** (other Unix systems should work with minor modifications)
- **Homebrew** package manager
- **GNU Stow** for symlink management
- **Git** for version control
- **Zsh** as the shell
- **Starship** prompt (installed automatically)
- **Luarocks** for Neovim plugin management (required for some nvim plugins)
- **Ripgrep** for fast text search in Neovim/Telescope
- **Neovim** for text editing (optional but recommended)
- **Tmux** for terminal multiplexing (optional but recommended)
- **Node.js** for some LSP servers and development tools (optional but recommended)

## Installation

### Quick Install

1. Clone this repository:
   ```bash
   git clone https://github.com/ianlivingstone/dotfiles.git ~/.dotfiles
   ```

2. Install dependencies:
   ```bash
   # Install Homebrew if not already installed
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   
   # Install required dependencies
   brew install stow starship luarocks ripgrep
   
   # Install optional but recommended tools
   brew install neovim tmux node
   ```

3. Run the installation script:
   ```bash
   cd ~/.dotfiles
   ./dotfiles.sh install
   ```

4. Restart your shell or source the configuration:
   ```bash
   source ~/.zshrc
   ```

### Manual Installation

If you prefer to install packages individually:

```bash
cd ~/.dotfiles

# Install specific packages
stow shell    # Zsh configuration
stow git      # Git configuration  
stow tmux     # Tmux configuration
stow misc     # Miscellaneous tools
stow nvim     # Neovim configuration
```

## Package Structure

```
dotfiles/
├── shell/          # Zsh configuration
│   ├── .zshrc
│   └── .zprofile
├── git/            # Git configuration
│   └── .gitconfig
├── tmux/           # Tmux configuration
│   └── .tmux.conf
├── misc/           # Miscellaneous tools
│   ├── .dircolors
│   └── starship.toml
├── nvim/           # Neovim configuration
│   └── .config/nvim/init.lua
└── dotfiles.sh     # Installation/management script
```

## Usage

```bash
./dotfiles.sh install    # Install dotfiles with GNU Stow
./dotfiles.sh status     # Check symlink status  
./dotfiles.sh uninstall  # Remove all symlinks
./dotfiles.sh help       # Show all commands
```

**Dependencies**: GNU Stow, Starship, Git, Zsh, Luarocks, Ripgrep (auto-checked on install)

## Customization

Feel free to fork this repository and customize the configurations to your needs. The modular structure makes it easy to add or remove packages.

## What You Get

### Shell Status Message
Every new shell displays a one-line status with:
```
🏠 user@hostname ~/directory | ⏱ uptime | 📦 git-branch ✓ | 🕐 time
```

### Starship Prompt
- **Language Detection**: Automatically shows versions for Node.js, Go, Python, Rust, Java
- **Git Integration**: Clean status indicators (✓ clean, ± dirty, ⇡ ahead)
- **Context Aware**: Shows Docker, Kubernetes, AWS context when relevant
- **Fast & Lightweight**: Only loads modules when needed

### Neovim Features
- **LSP Integration**: Full language server support for TypeScript, Go, and more
- **Smart Autocompletion**: Context-aware suggestions with snippets
- **File Navigation**: Fuzzy finding with Telescope (files, text search, buffers)
- **Auto-formatting**: Automatic code formatting and import organization on save
- **Syntax Highlighting**: Advanced syntax highlighting with Treesitter
- **Plugin Management**: Modern plugin management with lazy loading

### Key Bindings
- **Leader key**: `<Space>`
- **Save**: `<leader>w`
- **Quit**: `<leader>q`
- **File finder**: `<leader>ff` (Telescope)
- **Text search**: `<leader>fg` (Telescope live grep)
- **Buffer switcher**: `<leader>fb` (Telescope buffers)
- **Go organize imports**: `<leader>gi` (Go files only)

## Dependencies Included

- **Starship**: Fast, customizable prompt with language detection
- **SSH Agent**: Automatic SSH key management
- **GPG Agent**: GPG key management with SSH support
- **NVM**: Node.js version management
- **GVM**: Go version management  
- **Cargo**: Rust package manager integration