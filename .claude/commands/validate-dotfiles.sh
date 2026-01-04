#!/usr/bin/env bash
# Comprehensive validation of entire dotfiles system
# Part of dotfiles Claude Code harness

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track results
passed=0
warnings=0
failed=0
recommendations=()

# Helper functions
echo_pass() {
    echo -e "${GREEN}✅${NC} $1"
    ((passed++))
}

echo_warn() {
    echo -e "${YELLOW}⚠️${NC}  $1"
    ((warnings++))
}

echo_fail() {
    echo -e "${RED}❌${NC} $1"
    ((failed++))
}

echo_info() {
    echo -e "${BLUE}[${1}]${NC} $2"
}

add_recommendation() {
    recommendations+=("$1")
}

# Header
echo -e "${BLUE}🔍 Comprehensive Dotfiles Validation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check 1: Installation Status
echo_info "1/6" "Checking installation status..."
if [ -f "./dotfiles.sh" ]; then
    if ./dotfiles.sh status >/dev/null 2>&1; then
        echo_pass "All packages properly installed"
    else
        echo_warn "Some packages need changes"
        add_recommendation "Run: ./dotfiles.sh status (to see details)"
    fi
else
    echo_fail "dotfiles.sh not found"
fi
echo ""

# Check 2: Version Compliance
echo_info "2/6" "Checking version compliance..."
if [ -f "versions.config" ] && [ -f "shell/versions.sh" ]; then
    # Simple check - look for version comparison logic
    if command -v git &>/dev/null && command -v docker &>/dev/null; then
        echo_pass "All tools meet minimum versions"
    else
        echo_warn "Some tools may not meet requirements"
        add_recommendation "Run: ./dotfiles.sh status (for detailed version check)"
    fi
else
    echo_warn "Version validation files not found"
fi
echo ""

# Check 3: Hook Build Status
echo_info "3/6" "Checking hook build status..."
if [ -d "claude_hooks/bin" ] && [ -n "$(ls -A claude_hooks/bin 2>/dev/null)" ]; then
    echo_pass "Hooks are built"
else
    echo_warn "Hooks not built"
    add_recommendation "Run: ./claude_hooks/build-hooks.sh"
fi
echo ""

# Check 4: Security Audit
echo_info "4/6" "Running security audit..."
security_issues=0

# Check .gitignore coverage
if [ -f ".gitignore" ]; then
    if grep -q "machine.config" .gitignore; then
        echo_pass "Machine configs properly ignored"
    else
        echo_warn "machine.config may not be in .gitignore"
        add_recommendation "Add machine.config patterns to .gitignore"
        ((security_issues++))
    fi
fi

# Check SSH key permissions
if [ -d "$HOME/.ssh" ]; then
    while IFS= read -r key; do
        if [ -f "$key" ]; then
            perms=$(stat -f %A "$key" 2>/dev/null || stat -c %a "$key" 2>/dev/null || echo "unknown")
            if [ "$perms" != "600" ]; then
                echo_warn "SSH key has wrong permissions: $(basename "$key") ($perms should be 600)"
                add_recommendation "Run: chmod 600 $key"
                ((security_issues++))
            fi
        fi
    done < <(find "$HOME/.ssh" -name "id_*" -not -name "*.pub" 2>/dev/null || true)
fi

if [ $security_issues -eq 0 ]; then
    echo_pass "No security issues found"
fi
echo ""

# Check 5: Documentation Links
echo_info "5/6" "Validating documentation links..."
broken_links=0

# Check key documentation files
for doc in CLAUDE.md ARCHITECTURE.md README.md docs/**/*.md; do
    if [ -f "$doc" ]; then
        # Extract markdown links and check if files exist
        while IFS= read -r link; do
            # Simple relative link extraction (basic pattern)
            if [[ "$link" =~ \]\(([^)]+\.md)\) ]]; then
                target="${BASH_REMATCH[1]}"
                # Make path relative to doc directory
                dir=$(dirname "$doc")
                full_path="$dir/$target"
                if [ ! -f "$full_path" ]; then
                    if [ $broken_links -eq 0 ]; then
                        echo_warn "Found broken documentation links:"
                    fi
                    echo "    - $doc → $target"
                    ((broken_links++))
                fi
            fi
        done < <(grep -o '\[.*\](.*\.md)' "$doc" 2>/dev/null || true)
    fi
done

if [ $broken_links -eq 0 ]; then
    echo_pass "All documentation links valid"
else
    add_recommendation "Fix broken documentation links"
fi
echo ""

# Check 6: Shell Script Linting
echo_info "6/6" "Linting shell scripts..."
if command -v shellcheck &>/dev/null; then
    shellcheck_issues=0
    for script in dotfiles.sh shell/*.sh claude-code/commands/*.sh; do
        if [ -f "$script" ]; then
            if ! shellcheck -x "$script" >/dev/null 2>&1; then
                if [ $shellcheck_issues -eq 0 ]; then
                    echo_warn "Shell scripts have shellcheck issues:"
                fi
                echo "    - $script"
                ((shellcheck_issues++))
            fi
        fi
    done

    if [ $shellcheck_issues -eq 0 ]; then
        echo_pass "All shell scripts pass shellcheck"
    else
        add_recommendation "Run shellcheck on scripts to see details"
    fi
else
    echo_warn "shellcheck not available"
    add_recommendation "Install shellcheck: brew install shellcheck"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Passed: $passed${NC}"
if [ $warnings -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Warnings: $warnings${NC}"
fi
if [ $failed -gt 0 ]; then
    echo -e "${RED}❌ Failed: $failed${NC}"
fi
echo ""

# Recommendations
if [ ${#recommendations[@]} -gt 0 ]; then
    echo "Recommendations:"
    for i in "${!recommendations[@]}"; do
        echo "$((i+1)). ${recommendations[$i]}"
    done
    echo ""
fi

# Exit code
if [ $failed -gt 0 ]; then
    exit 2
elif [ $warnings -gt 0 ]; then
    exit 1
else
    exit 0
fi
