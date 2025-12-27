#!/usr/bin/env bash
# Git status overview with clear sections for staged, unstaged, and untracked changes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not a git repository${NC}" >&2
    exit 1
fi

# Get current branch
current_branch=$(git branch --show-current)

# Get tracking info
tracking_info=$(git status --porcelain=v1 --branch | head -1)

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📊 Git Status Overview${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Branch:${NC} $current_branch"

# Check if branch has upstream
if git rev-parse --abbrev-ref @{upstream} > /dev/null 2>&1; then
    upstream=$(git rev-parse --abbrev-ref @{upstream})
    ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
    behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")

    echo -e "${BLUE}Upstream:${NC} $upstream"

    if [[ "$ahead" -gt 0 ]] && [[ "$behind" -gt 0 ]]; then
        echo -e "${YELLOW}Status:${NC} ↑ $ahead ahead, ↓ $behind behind"
    elif [[ "$ahead" -gt 0 ]]; then
        echo -e "${GREEN}Status:${NC} ↑ $ahead ahead"
    elif [[ "$behind" -gt 0 ]]; then
        echo -e "${YELLOW}Status:${NC} ↓ $behind behind"
    else
        echo -e "${GREEN}Status:${NC} Up to date"
    fi
else
    echo -e "${YELLOW}Upstream:${NC} No tracking branch"
fi

echo ""

# Get staged changes
staged_files=$(git diff --cached --name-status)
staged_count=$(git diff --cached --name-only | wc -l | tr -d ' ')

# Get unstaged changes
unstaged_files=$(git diff --name-status)
unstaged_count=$(git diff --name-only | wc -l | tr -d ' ')

# Get untracked files
untracked_files=$(git ls-files --others --exclude-standard)
untracked_count=$(echo "$untracked_files" | { grep -v '^$' || true; } | wc -l | tr -d ' ')

# Display staged changes
echo -e "${GREEN}✓ Staged Changes${NC} (ready to commit: $staged_count files)"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [[ "$staged_count" -gt 0 ]]; then
    while IFS=$'\t' read -r status file; do
        case "$status" in
            A) echo -e "  ${GREEN}A${NC}  $file" ;;
            M) echo -e "  ${BLUE}M${NC}  $file" ;;
            D) echo -e "  ${RED}D${NC}  $file" ;;
            R*) echo -e "  ${CYAN}R${NC}  $file" ;;
            C*) echo -e "  ${CYAN}C${NC}  $file" ;;
            *) echo -e "  ${YELLOW}?${NC}  $file" ;;
        esac
    done <<< "$staged_files"
else
    echo -e "  ${YELLOW}(no staged changes)${NC}"
fi

echo ""

# Display unstaged changes
echo -e "${YELLOW}⚠ Unstaged Changes${NC} (modified but not staged: $unstaged_count files)"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [[ "$unstaged_count" -gt 0 ]]; then
    while IFS=$'\t' read -r status file; do
        case "$status" in
            M) echo -e "  ${YELLOW}M${NC}  $file" ;;
            D) echo -e "  ${RED}D${NC}  $file" ;;
            *) echo -e "  ${YELLOW}?${NC}  $file" ;;
        esac
    done <<< "$unstaged_files"
else
    echo -e "  ${GREEN}(no unstaged changes)${NC}"
fi

echo ""

# Display untracked files
echo -e "${BLUE}+ Untracked Files${NC} (not tracked by git: $untracked_count files)"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [[ "$untracked_count" -gt 0 ]]; then
    while read -r file; do
        if [[ -n "$file" ]]; then
            echo -e "  ${BLUE}?${NC}  $file"
        fi
    done <<< "$untracked_files"
else
    echo -e "  ${GREEN}(no untracked files)${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Summary and suggestions
total_changes=$((staged_count + unstaged_count + untracked_count))

if [[ "$total_changes" -eq 0 ]]; then
    echo -e "${GREEN}✨ Working tree clean - nothing to commit${NC}"
elif [[ "$staged_count" -gt 0 ]] && [[ "$unstaged_count" -eq 0 ]] && [[ "$untracked_count" -eq 0 ]]; then
    echo -e "${GREEN}✅ Ready to commit!${NC} Run: ${BLUE}/commit${NC}"
elif [[ "$staged_count" -gt 0 ]] && [[ "$unstaged_count" -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  You have both staged and unstaged changes${NC}"
    echo -e "   Stage remaining changes: ${BLUE}git add <files>${NC}"
    echo -e "   Or commit staged only: ${BLUE}/commit${NC} ${RED}(will fail - use stash first)${NC}"
elif [[ "$staged_count" -eq 0 ]] && [[ "$unstaged_count" -gt 0 ]]; then
    echo -e "${YELLOW}💡 Stage changes to commit:${NC} ${BLUE}git add <files>${NC}"
elif [[ "$staged_count" -eq 0 ]] && [[ "$untracked_count" -gt 0 ]]; then
    echo -e "${BLUE}💡 Add untracked files:${NC} ${BLUE}git add <files>${NC}"
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
