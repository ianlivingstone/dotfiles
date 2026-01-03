#!/usr/bin/env zsh
# Core shell configuration - basic settings and PATH setup
# SOURCED MODULE: Uses graceful error handling, never use set -e

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# General Config
export GPG_TTY=$(tty)
eval $(brew shellenv)

# Fix compinit security check
ZSH_DISABLE_COMPFIX=true

# Initialize completion system with caching
# Only rebuild completion dump once per day for faster startup
autoload -Uz compinit
setopt EXTENDEDGLOB
local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n $zcompdump(#qNmh-20) ]]; then
    # Dump file is less than 20 hours old, skip rebuild
    compinit -C -u
else
    # Rebuild completion dump
    compinit -u
fi
unsetopt EXTENDEDGLOB