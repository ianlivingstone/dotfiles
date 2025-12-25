#!/usr/bin/env bash
# Automated commit script with AI-generated messages
# Validates git state, analyzes changes, and creates commits

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Not a git repository${NC}" >&2
        exit 1
    fi
}

# Function to check for staged changes
check_staged_changes() {
    if ! git diff --cached --quiet; then
        return 0  # Has staged changes
    else
        return 1  # No staged changes
    fi
}

# Function to check for unstaged changes
check_unstaged_changes() {
    if ! git diff --quiet; then
        return 0  # Has unstaged changes
    else
        return 1  # No unstaged changes
    fi
}

# Function to check for untracked files
check_untracked_files() {
    if [[ -n $(git ls-files --others --exclude-standard) ]]; then
        return 0  # Has untracked files
    else
        return 1  # No untracked files
    fi
}

# Main validation function
validate_commit_state() {
    check_git_repo

    local has_staged=false
    local has_unstaged=false
    local has_untracked=false

    if check_staged_changes; then
        has_staged=true
    fi

    if check_unstaged_changes; then
        has_unstaged=true
    fi

    if check_untracked_files; then
        has_untracked=true
    fi

    # No changes at all
    if [[ "$has_staged" == "false" ]] && [[ "$has_unstaged" == "false" ]] && [[ "$has_untracked" == "false" ]]; then
        echo -e "${YELLOW}⚠️  No changes detected${NC}"
        echo "Nothing to commit, working tree clean"
        exit 1
    fi

    # No staged changes
    if [[ "$has_staged" == "false" ]]; then
        echo -e "${YELLOW}⚠️  No staged changes${NC}"
        echo "Please stage changes first with: ${BLUE}git add <files>${NC}"

        if [[ "$has_unstaged" == "true" ]]; then
            echo ""
            echo "Modified files:"
            git status --short | grep '^ M'
        fi

        if [[ "$has_untracked" == "true" ]]; then
            echo ""
            echo "Untracked files:"
            git status --short | grep '^??'
        fi

        exit 1
    fi

    # Has unstaged changes (the critical check we want)
    if [[ "$has_unstaged" == "true" ]]; then
        echo -e "${RED}❌ Error: Unstaged changes detected${NC}"
        echo "The working tree must be clean (only staged changes allowed)"
        echo ""
        echo "Unstaged changes:"
        git status --short | grep '^ M'
        echo ""
        echo "Options:"
        echo "  1. Stage them: ${BLUE}git add <files>${NC} (if they should be in this commit)"
        echo "  2. Stash them: ${BLUE}git stash${NC} (if they should not be in this commit)"
        echo "  3. Commit separately (if they're unrelated changes)"
        exit 1
    fi

    # All checks passed
    echo -e "${GREEN}✅ Ready to commit${NC}"
    echo "Staged changes:"
    git status --short | grep '^[MARC]'
    return 0
}

# Function to get recent commit messages for style analysis
get_recent_commits() {
    git log -10 --pretty=format:"%s" --no-merges
}

# Function to get staged diff
get_staged_diff() {
    git diff --cached
}

# Function to get staged diff stats
get_staged_stats() {
    git diff --cached --stat
}

# Function to create commit with message file
create_commit() {
    local msg_file="$1"

    if [[ ! -f "$msg_file" ]]; then
        echo -e "${RED}❌ Error: Commit message file not found: $msg_file${NC}" >&2
        exit 1
    fi

    if git commit -F "$msg_file"; then
        echo -e "${GREEN}✅ Commit created successfully${NC}"
        echo ""
        git log -1 --pretty=format:"%C(yellow)%h%Creset %s"
        echo ""
        return 0
    else
        echo -e "${RED}❌ Commit failed${NC}" >&2
        return 1
    fi
}

# Function to display commit context for AI
display_commit_context() {
    echo -e "${BLUE}━━━ Recent Commit Style ━━━${NC}"
    get_recent_commits
    echo ""
    echo -e "${BLUE}━━━ Staged Changes Stats ━━━${NC}"
    get_staged_stats
    echo ""
    echo -e "${BLUE}━━━ Staged Changes Diff ━━━${NC}"
    get_staged_diff
}

# Main workflow
main() {
    echo -e "${GREEN}🤖 AI Commit Generator${NC}"
    echo ""

    # Validate state
    if ! validate_commit_state; then
        exit 1
    fi

    echo ""
    echo -e "${BLUE}📊 Gathering context for commit message...${NC}"
    echo ""

    # Display all context
    display_commit_context

    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✍️  Commit Message Guidelines:${NC}"
    echo "  • First line: concise summary (50-72 chars max)"
    echo "  • Use imperative mood: 'Add feature' not 'Added feature'"
    echo "  • Match repository style (use feat:/fix: if others do)"
    echo "  • Be specific: 'Add gopls config' not 'Update files'"
    echo "  • Focus on WHAT and WHY, not HOW"
    echo ""
    echo "  MUST include footer:"
    echo "    🤖 Generated with [Claude Code](https://claude.com/claude-code)"
    echo ""
    echo "    Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Main command dispatcher
case "${1:-main}" in
    main)
        main
        ;;
    validate)
        validate_commit_state
        ;;
    recent-commits)
        get_recent_commits
        ;;
    staged-diff)
        get_staged_diff
        ;;
    staged-stats)
        get_staged_stats
        ;;
    commit)
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}❌ Error: Message file path required${NC}" >&2
            exit 1
        fi
        create_commit "$2"
        ;;
    *)
        echo "Usage: $0 [validate|recent-commits|staged-diff|staged-stats|commit <msg-file>]"
        echo "Default: run full workflow and display context for AI"
        exit 1
        ;;
esac
