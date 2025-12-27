#!/usr/bin/env bash
# Automated commit script with AI-generated messages
# Validates git state, analyzes changes, and creates commits

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Not a git repository${NC}" >&2
        exit 1
    fi
}

# Function to check if GPG signing is required
is_gpg_signing_required() {
    # Check commit.gpgsign config
    local gpg_sign=$(git config --get commit.gpgsign 2>/dev/null || echo "false")
    [[ "$gpg_sign" == "true" ]]
}

# Function to check if GPG agent is working
is_gpg_agent_working() {
    # Check if gpg command exists
    if ! command -v gpg &>/dev/null; then
        return 1
    fi

    # Check if gpg-agent is running
    if ! pgrep -x "gpg-agent" > /dev/null 2>&1; then
        return 1
    fi

    # Check if agent is responsive
    if ! gpg-connect-agent --quiet /bye &>/dev/null; then
        return 1
    fi

    # Check if signing key is configured
    local signing_key=$(git config --get user.signingkey 2>/dev/null)
    if [[ -z "$signing_key" ]]; then
        return 1
    fi

    # Check if the key exists and is usable
    if ! gpg --list-secret-keys "$signing_key" &>/dev/null; then
        return 1
    fi

    return 0
}

# Function to test if GPG key passphrase is cached
# This is critical because Claude Code cannot render interactive GPG password prompts.
# If the passphrase is not cached, git commit will hang waiting for input that cannot be provided.
# By testing first, we can detect this situation and provide clear instructions to the user.
test_gpg_signing() {
    local signing_key=$(git config --get user.signingkey 2>/dev/null)

    # Try a test sign operation with --batch and --no-tty flags
    # If passphrase is cached in gpg-agent, this will succeed immediately
    # If passphrase is needed, this will fail without prompting
    echo "test" | gpg --sign --local-user "$signing_key" --batch --no-tty -o /dev/null 2>/dev/null
    return $?
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

    # All checks passed - ready to commit staged changes
    echo -e "${GREEN}✅ Ready to commit${NC}"
    echo "Staged changes:"
    git status --short | grep '^[MARC]'

    # Show unstaged/untracked if present (informational only)
    if [[ "$has_unstaged" == "true" ]] || [[ "$has_untracked" == "true" ]]; then
        echo ""
        echo -e "${CYAN}ℹ️  Note: Unstaged/untracked changes will not be included in this commit${NC}"
    fi

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

    # Check if GPG signing is required
    if is_gpg_signing_required; then
        echo -e "${CYAN}🔐 GPG signing is required for commits${NC}"

        # Check if GPG agent is working
        if ! is_gpg_agent_working; then
            echo -e "${RED}❌ GPG agent is not properly configured${NC}"
            echo ""
            echo -e "${CYAN}Commit message saved to: $msg_file${NC}"
            echo ""
            echo -e "${YELLOW}To complete the commit, run:${NC}"
            echo -e "${BLUE}git commit -F \"$msg_file\"${NC}"
            echo ""
            echo -e "${CYAN}💡 Troubleshooting GPG:${NC}"
            echo "  • Check GPG agent: gpg-connect-agent /bye"
            echo "  • Verify signing key: git config user.signingkey"
            echo "  • List secret keys: gpg --list-secret-keys"
            echo "  • Start GPG agent: gpgconf --launch gpg-agent"
            return 1
        fi

        echo -e "${GREEN}✅ GPG agent is running and key is available${NC}"

        # Test if passphrase is cached
        echo -e "${BLUE}Testing GPG key passphrase...${NC}"
        if ! test_gpg_signing; then
            local signing_key=$(git config --get user.signingkey 2>/dev/null)
            echo -e "${YELLOW}⚠️  GPG key passphrase is not cached${NC}"
            echo ""
            echo -e "${CYAN}Commit message saved to: $msg_file${NC}"
            echo ""
            echo -e "${YELLOW}Unlock your GPG key, then run:${NC}"
            echo -e "${BLUE}git commit -F \"$msg_file\"${NC}"
            echo ""
            echo -e "${CYAN}💡 To cache your passphrase, run:${NC}"
            echo -e "${BLUE}echo \"test\" | gpg --sign --local-user $signing_key --armor -o /dev/null${NC}"
            echo ""
            echo "This will prompt for your passphrase and cache it for future operations."
            return 1
        fi

        echo -e "${GREEN}✅ GPG key passphrase is cached${NC}"
        echo -e "${BLUE}Attempting to commit...${NC}"
        echo ""

        if git commit -F "$msg_file"; then
            echo ""
            echo -e "${GREEN}✅ Commit created successfully${NC}"
            echo ""
            git log -1 --pretty=format:"%C(yellow)%h%Creset %s"
            echo ""
            return 0
        else
            echo -e "${RED}❌ Commit failed${NC}" >&2
            return 1
        fi
    else
        # No GPG signing required
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

# Function to generate unique commit message filename
generate_commit_filename() {
    # Use base64 encoded random data for uniqueness
    local random_id=$(head -c 12 /dev/urandom | base64 | tr -d '/+=' | head -c 16)
    echo "/tmp/commit-msg-${random_id}.txt"
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
    echo ""
    echo -e "${CYAN}💡 Next steps:${NC}"
    echo "  1. Write commit message to: ${BLUE}$(generate_commit_filename)${NC}"
    echo "  2. Run: ${BLUE}~/.claude/commands/commit.sh commit <filename>${NC}"
    echo ""
    echo -e "${CYAN}Or generate a unique filename:${NC}"
    echo "  ${BLUE}~/.claude/commands/commit.sh generate-filename${NC}"
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
    generate-filename)
        generate_commit_filename
        ;;
    commit)
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}❌ Error: Message file path required${NC}" >&2
            exit 1
        fi
        create_commit "$2"
        ;;
    *)
        echo "Usage: $0 [validate|recent-commits|staged-diff|staged-stats|generate-filename|commit <msg-file>]"
        echo "Default: run full workflow and display context for AI"
        exit 1
        ;;
esac
