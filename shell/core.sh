# Core shell configuration - basic settings and PATH setup

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# General Config
export PATH=/opt/homebrew/bin:$PATH
export GPG_TTY=$(tty)
eval $(brew shellenv)

# Fix compinit security check
ZSH_DISABLE_COMPFIX=true

# Initialize completion system properly
autoload -Uz compinit
compinit -u