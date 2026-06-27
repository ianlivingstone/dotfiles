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

# Pager: enable mouse-wheel scrolling in less (git diff, git add -p, man, etc.).
#   -F quit if it fits one screen, -R keep colors, --mouse wheel scroll (less 550+),
#   --wheel-lines=3 for smoother scrolling. (Replaces git's default LESS=FRX; we drop
#   -X because it interferes with the alt-screen that mouse reporting needs.)
export LESS="-FR --mouse --wheel-lines=3"

# Homebrew environment — cache `brew shellenv` output instead of forking brew on
# every shell. Regenerate only when the brew binary is newer than the cache.
local brew_bin=""
local _b
for _b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$_b" ]] && { brew_bin="$_b"; break; }
done
if [[ -n "$brew_bin" ]]; then
    local brew_cache="${XDG_CACHE_HOME}/dotfiles/brew_shellenv.zsh"
    if [[ ! -s "$brew_cache" || "$brew_bin" -nt "$brew_cache" ]]; then
        mkdir -p "${brew_cache:h}" && chmod 700 "${brew_cache:h}"
        # Write atomically (a partial/failed shellenv must never be sourced) and as 0600
        # (umask 077) — this file is sourced at startup, so keep it owner-only.
        local brew_tmp="${brew_cache}.$$"
        if ( umask 077; "$brew_bin" shellenv > "$brew_tmp" 2>/dev/null ) && [[ -s "$brew_tmp" ]]; then
            mv -f "$brew_tmp" "$brew_cache"
        else
            rm -f "$brew_tmp"
        fi
    fi
    [[ -s "$brew_cache" ]] && source "$brew_cache"
fi

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

# Completion behavior + caching.
# use-cache makes expensive completers (brew, git, etc.) store their results
# instead of recomputing the list on every Tab press — this is the main fix for
# "tab completion is slow sometimes". The rest are quality-of-life: an arrow-key
# menu and case-insensitive matching.
local zcompcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
mkdir -p "$zcompcache" && chmod 700 "$zcompcache"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$zcompcache"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'