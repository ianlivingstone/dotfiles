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

    # Use --pinentry-mode loopback to prevent pinentry from being launched
    # This forces GPG to fail immediately if passphrase is not cached
    # See: https://dev.gnupg.org/T4677
    echo "test" | gpg --sign --local-user "$signing_key" --batch --no-tty --pinentry-mode loopback -o /dev/null 2>/dev/null
    return $?
}

# Unified GPG status check function
# Returns 0 if ready to commit, 1 if not (with error messages)
check_gpg_status() {
    local quiet="${1:-false}"  # Pass "true" to suppress success messages

    if ! is_gpg_signing_required; then
        [[ "$quiet" != "true" ]] && echo -e "${GREEN}✅ GPG signing not required${NC}"
        return 0
    fi

    if ! is_gpg_agent_working; then
        echo -e "${RED}❌ GPG agent not configured${NC}"
        echo -e "${YELLOW}Fix: gpgconf --launch gpg-agent${NC}"
        return 1
    fi

    if test_gpg_signing; then
        [[ "$quiet" != "true" ]] && echo -e "${GREEN}✅ GPG key unlocked and ready${NC}"
        return 0
    else
        local signing_key=$(git config --get user.signingkey 2>/dev/null)
        echo -e "${RED}❌ GPG key is locked${NC}"
        echo ""
        echo -e "${CYAN}💡 To unlock your key, run:${NC}"
        echo -e "${BLUE}echo \"test\" | gpg --sign --local-user $signing_key --armor -o /dev/null${NC}"
        echo ""
        echo -e "${YELLOW}Then enter your passphrase when prompted.${NC}"
        return 1
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

# Function to get all commit context in one call (optimized)
get_commit_context() {
    # Single git invocation to get everything needed
    cat <<EOF
━━━ Recent Commit Style ━━━
$(git log -5 --pretty=format:"%s" --no-merges)

━━━ Staged Changes ━━━
$(git diff --cached --stat)

━━━ Detailed Diff ━━━
$(git diff --cached | head -100)
EOF
}

# Legacy functions for backward compatibility (now just call combined version)
get_recent_commits() {
    git log -5 --pretty=format:"%s" --no-merges
}

get_staged_diff() {
    git diff --cached | head -100
}

get_staged_stats() {
    git diff --cached --stat
}

# Function to create commit with message from stdin or file
create_commit() {
    local commit_msg=""
    local temp_file=""
    local cleanup_temp=false

    # Read commit message from stdin if available, otherwise from file
    if [[ -p /dev/stdin ]] || [[ ! -t 0 ]]; then
        # Reading from stdin (pipe or redirect)
        commit_msg=$(cat)
        # Create temporary file for git commit
        temp_file=$(mktemp)
        echo "$commit_msg" > "$temp_file"
        cleanup_temp=true
    elif [[ -n "${1:-}" ]]; then
        # Reading from file argument
        local msg_file="$1"
        if [[ ! -f "$msg_file" ]]; then
            echo -e "${RED}❌ Error: Commit message file not found: $msg_file${NC}" >&2
            exit 1
        fi
        temp_file="$msg_file"
    else
        echo -e "${RED}❌ Error: No commit message provided${NC}" >&2
        echo "Usage: commit.sh commit <file>  OR  echo \"message\" | commit.sh commit"
        exit 1
    fi

    # Cleanup function for temporary file
    cleanup() {
        if [[ "${cleanup_temp:-false}" == "true" ]] && [[ -f "${temp_file:-}" ]]; then
            rm -f "$temp_file"
        fi
    }
    trap cleanup EXIT

    # Check if GPG signing is required
    if is_gpg_signing_required; then
        echo -e "${CYAN}🔐 GPG signing required${NC}"

        # Check if GPG agent is working
        if ! is_gpg_agent_working; then
            echo -e "${RED}❌ GPG agent not configured${NC}"
            echo -e "${YELLOW}Fix: gpgconf --launch gpg-agent${NC}"
            return 1
        fi

        # Smart GPG detection: only fail if non-interactive AND passphrase not cached
        local is_interactive=false
        if [[ -t 0 ]] && [[ -t 1 ]]; then
            is_interactive=true
        fi

        # Test if passphrase is cached
        local passphrase_cached=false
        if test_gpg_signing; then
            passphrase_cached=true
        fi

        # Decision logic
        if [[ "$is_interactive" == "true" ]]; then
            # Interactive: allow GPG to prompt for passphrase
            echo -e "${GREEN}✅ Interactive mode - GPG can prompt for passphrase${NC}"
        elif [[ "$passphrase_cached" == "true" ]]; then
            # Non-interactive but passphrase cached: safe to proceed
            echo -e "${GREEN}✅ Passphrase cached - can commit without prompts${NC}"
        else
            # Non-interactive and passphrase NOT cached: will hang, fail now
            local signing_key=$(git config --get user.signingkey 2>/dev/null)
            echo -e "${RED}❌ Cannot commit: non-interactive mode and passphrase not cached${NC}"
            echo ""
            if [[ "$cleanup_temp" == "false" ]]; then
                echo -e "${CYAN}Commit message saved: $temp_file${NC}"
                echo -e "${YELLOW}Run manually:${NC} ${BLUE}git commit -F \"$temp_file\"${NC}"
            fi
            echo ""
            echo -e "${CYAN}💡 To cache passphrase:${NC}"
            echo -e "${BLUE}echo \"test\" | gpg --sign --local-user $signing_key --armor -o /dev/null${NC}"
            return 1
        fi

        # Proceed with commit
        if git commit -F "$temp_file"; then
            echo -e "${GREEN}✅ Commit created${NC}"
            git log -1 --pretty=format:"%C(yellow)%h%Creset %s"
            echo ""
            return 0
        else
            echo -e "${RED}❌ Commit failed${NC}" >&2
            return 1
        fi
    else
        # No GPG signing required
        if git commit -F "$temp_file"; then
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

# Function to display commit context for AI (optimized)
display_commit_context() {
    echo -e "${BLUE}"
    get_commit_context
    echo -e "${NC}"
}

# Function to generate unique commit message filename
generate_commit_filename() {
    # Use base64 encoded random data for uniqueness
    local random_id=$(head -c 12 /dev/urandom | base64 | tr -d '/+=' | head -c 16)
    echo "/tmp/commit-msg-${random_id}.txt"
}

# Function to generate commit message using Claude
generate_commit_message_ai() {
    local temp_context=$(mktemp)

    # Gather all context
    {
        echo "=== Recent Commit Style ==="
        get_recent_commits
        echo ""
        echo "=== Staged Changes Stats ==="
        get_staged_stats
        echo ""
        echo "=== Staged Changes Diff ==="
        get_staged_diff
    } > "$temp_context"

    # Call Claude to generate commit message using --print mode
    # CRITICAL: Request raw output only, no markdown, no explanation
    local raw_response=$(claude -p "Generate a git commit message based on the context below.

CRITICAL INSTRUCTIONS:
- Output ONLY the raw commit message text
- NO markdown code blocks, NO backticks, NO explanation text
- NO 'Here is the commit message:' or similar preamble
- Just the commit message itself, ready to paste into git commit

Follow these commit message rules:

**Subject Line:**
- Max 50-72 characters
- Imperative mood: 'Add feature' not 'Added feature'
- Start with verb: Add, Fix, Update, Remove, Refactor, etc.
- Be specific: 'Add gopls config' not 'Update files'
- No period at end

**Body (optional):**
- Explain WHY, not what (diff shows what)
- Wrap at 72 characters
- Blank line after subject

**Footer (REQUIRED - must be included):**
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

Match the style of recent commits. Here's the context:

$(cat "$temp_context")")

    rm -f "$temp_context"

    # Extract commit message from response (handles markdown-wrapped or raw text)
    local commit_msg="$raw_response"

    # If response contains markdown code blocks, extract the content
    if echo "$raw_response" | grep -q '```'; then
        # Extract text between first ``` and last ```
        commit_msg=$(echo "$raw_response" | sed -n '/```/,/```/p' | sed '1d;$d' | sed '/^```/d')
    fi

    # Remove any leading/trailing whitespace
    commit_msg=$(echo "$commit_msg" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    echo "$commit_msg"
}

# AI commit workflow
# Automatically detects if running interactively or in automation
ai_commit() {
    echo -e "${GREEN}🤖 AI-Assisted Commit${NC}"
    echo ""

    # Step 1: Validate state
    if ! validate_commit_state; then
        exit 1
    fi
    echo ""

    # Step 2: Check GPG status using unified check
    if is_gpg_signing_required; then
        echo -e "${CYAN}🔐 Checking GPG status...${NC}"
        if ! check_gpg_status "quiet"; then
            exit 1
        fi
        echo -e "${GREEN}✅ GPG ready${NC}"
        echo ""
    fi

    # Step 3: Generate commit message with AI
    echo -e "${CYAN}📝 Generating commit message with Claude...${NC}"
    local commit_msg=$(generate_commit_message_ai)

    # Step 4: Show message
    echo ""
    echo -e "${GREEN}Generated commit message:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$commit_msg"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Detect if running in interactive terminal
    if [[ -t 0 ]] && [[ -t 1 ]]; then
        # Interactive mode - prompt for approval
        read -p "Commit with this message? (y/n/e=edit): " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Commit with generated message
            echo "$commit_msg" | create_commit
        elif [[ $REPLY =~ ^[Ee]$ ]]; then
            # Open in editor
            local temp_file=$(mktemp)
            echo "$commit_msg" > "$temp_file"
            ${EDITOR:-vim} "$temp_file"
            create_commit "$temp_file"
            rm -f "$temp_file"
        else
            echo -e "${YELLOW}❌ Commit cancelled${NC}"
            exit 1
        fi
    else
        # Non-interactive mode (automation/Claude Code) - auto-approve
        echo -e "${CYAN}🤖 Auto-committing (non-interactive mode)...${NC}"
        echo "$commit_msg" | create_commit
    fi
}

# Main workflow (simplified)
main() {
    echo -e "${GREEN}🤖 Commit Context${NC}"
    echo ""

    # Validate state
    if ! validate_commit_state; then
        exit 1
    fi

    echo ""
    # Display all context in one go
    display_commit_context

    echo ""
    echo -e "${CYAN}📝 Commit Guidelines:${NC}"
    echo "• Subject: <verb> <what> (50-72 chars, imperative mood)"
    echo "• Body: WHY, not what (optional)"
    echo "• Footer: Claude Code attribution (required)"
    echo ""
    echo -e "${CYAN}💡 Use: git commit -S -m \"\$(cat <<'EOF' ... EOF)\"${NC}"
}

# Main command dispatcher
case "${1:-main}" in
    main)
        main
        ;;
    ai)
        # AI-assisted commit (calls Claude CLI)
        # Auto-detects interactive vs non-interactive mode
        ai_commit
        ;;
    validate)
        validate_commit_state
        ;;
    gpg-status)
        # Check GPG signing status - returns 0 if ready, 1 if not
        check_gpg_status
        exit $?
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
        # Accept stdin or file argument
        create_commit "${2:-}"
        ;;
    *)
        echo "Usage: $0 [ai|validate|gpg-status|recent-commits|staged-diff|staged-stats|generate-filename|commit [file]]"
        echo "  ai: AI-assisted commit (auto-detects interactive vs automated mode)"
        echo "  gpg-status: Check if GPG key is unlocked and ready for signing"
        echo "  commit: Pass message via stdin OR file argument"
        echo "  Example: echo \"message\" | $0 commit"
        echo "  Example: $0 commit /path/to/message.txt"
        echo "Default: run full workflow and display context for AI"
        exit 1
        ;;
esac
