# Ian Livingstone's Dotfiles

My personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) for easy installation and organization.

## Features

- **Shell**: Zsh configuration with Starship prompt and startup status message
- **Git**: Git configuration and aliases
- **Neovim**: Modern Vim configuration
- **Tmux**: Terminal multiplexer setup
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
   
   # Install GNU Stow and Starship
   brew install stow starship
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

**Dependencies**: GNU Stow, Starship, Git, Zsh (auto-checked on install)

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

## Dependencies Included

- **Starship**: Fast, customizable prompt with language detection
- **SSH Agent**: Automatic SSH key management
- **GPG Agent**: GPG key management with SSH support
- **NVM**: Node.js version management
- **GVM**: Go version management  
- **Cargo**: Rust package manager integration