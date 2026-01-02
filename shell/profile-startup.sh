#!/usr/bin/env zsh
# Profile .zshrc startup time
# Usage: zsh shell/profile-startup.sh

# Enable profiling
zmodload zsh/zprof

# Source the .zshrc
source ~/.zshrc

# Show profile report
zprof
