#!/usr/bin/env zsh
# Jujutsu (jj) integration and helper functions
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Check if current directory is a jj repository (colocated with git)
is_jj_repo() {
    # Check for jj working copy metadata in .git/jj/
    [[ -d .git/jj ]] && return 0

    # Alternative: check if jj status succeeds
    if command -v jj &> /dev/null; then
        jj status &> /dev/null && return 0
    fi

    return 1
}

# Get repository type (git, jj, or git+jj)
repo_type() {
    local has_git=false
    local has_jj=false

    # Check for git
    if git rev-parse --git-dir &> /dev/null; then
        has_git=true
    fi

    # Check for jj
    if is_jj_repo; then
        has_jj=true
    fi

    # Determine type
    if $has_git && $has_jj; then
        echo "git+jj (colocated)"
    elif $has_jj; then
        echo "jj"
    elif $has_git; then
        echo "git"
    else
        echo "none"
    fi
}

# Initialize jj in current git repository
jj_init() {
    if ! command -v jj &> /dev/null; then
        echo "❌ jj is not installed. Run: brew install jj"
        return 1
    fi

    if ! git rev-parse --git-dir &> /dev/null; then
        echo "❌ Not a git repository"
        return 1
    fi

    if is_jj_repo; then
        echo "✅ This repository already has jj initialized"
        return 0
    fi

    echo "🔧 Initializing jj in colocated mode (sharing .git directory)..."
    jj git init --colocate

    if [[ $? -eq 0 ]]; then
        echo "✅ jj initialized successfully!"
        echo "💡 You can now use both git and jj commands"
        echo "💡 Try: jj status"
    else
        echo "❌ Failed to initialize jj"
        return 1
    fi
}

# Show repository status with type indicator
repo_status() {
    local type=$(repo_type)

    echo "📁 Repository Type: $type"
    echo ""

    case $type in
        "git+jj (colocated)")
            echo "🔀 Git Status:"
            git status -s
            echo ""
            echo "🔀 Jujutsu Status:"
            jj status
            ;;
        "jj")
            jj status
            ;;
        "git")
            git status
            ;;
        "none")
            echo "❌ Not a git or jj repository"
            return 1
            ;;
    esac
}

# Alias for convenience
alias jj-init='jj_init'
alias jj-status='repo_status'
alias repo-type='repo_type'
