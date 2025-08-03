# Core shell configuration - basic settings and PATH setup

# General Config
export PATH=/opt/homebrew/bin:$PATH
export GPG_TTY=$(tty)
eval $(brew shellenv)

# Fix compinit security check
ZSH_DISABLE_COMPFIX=true

# Initialize completion system properly
autoload -Uz compinit
compinit -u