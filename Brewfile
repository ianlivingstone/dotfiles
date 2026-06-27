# Homebrew dependencies for this dotfiles setup.
#
# Installed automatically by:  ./dotfiles.sh install / reinstall / update
# Ad-hoc:                      brew bundle --file=Brewfile  (idempotent — skips what's present)
#
# This is the source of truth for brew packages.

# Core
brew "stow"          # symlink manager for the dotfiles
brew "git"
brew "zsh"
brew "gnupg"         # GPG (commit signing)

# Shell / prompt / terminal
brew "starship"      # prompt
brew "tmux"

# Editor + treesitter toolchain
brew "neovim"
brew "tree-sitter-cli"   # CLI nvim-treesitter (main branch) shells out to for `tree-sitter build`
                         # NOTE: the bare `tree-sitter` formula is the library only — no CLI binary
brew "luarocks"      # Neovim Lua rocks

# Version control
brew "tig"           # git TUI
brew "gh"            # GitHub CLI (used by the pr-review skill)
brew "jj"            # Jujutsu VCS (configured in jj/ and shell/jj.sh)

# Languages / runtimes
brew "uv"            # Python package/project manager (Python itself managed by uv)

# CLI utilities
brew "ripgrep"       # rg
brew "jq"
brew "just"
brew "duckdb"
brew "shellcheck"    # shell linting (Claude Code hooks + script validation)

# Containers
cask "docker-desktop"   # Docker Desktop — provides the engine, GUI, and the docker CLI

# ------------------------------------------------------------------------------
# Intentionally NOT managed here (installed/managed by other tooling):
#   brew    - bootstrap; installs itself
#   nvm     - Node version manager; custom XDG install + lazy-load (shell/nvm.sh)
#   gvm     - Go version manager; no Homebrew formula (shell/gvm.sh)
#   rustup  - self-managing toolchain installer (shell/rust.sh)
#   gopls   - installed via `go install` so it tracks the active Go toolchain
# ------------------------------------------------------------------------------
