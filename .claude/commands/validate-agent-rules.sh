#!/usr/bin/env bash
# Quick validation of Agent Rules format for AGENTS.md files
# Part of dotfiles Claude Code harness

set -euo pipefail

file="${1:-}"

if [[ -z "$file" ]]; then
    echo "Usage: $0 <AGENTS.md file>"
    exit 1
fi

if [[ ! -f "$file" ]]; then
    echo "❌ File not found: $file"
    exit 1
fi

# Track issues
issues=0

# Check for RFC 2119 keywords
if ! grep -qE '(MUST|SHOULD|MAY|MUST NOT|SHOULD NOT)' "$file"; then
    echo "⚠️  No RFC 2119 keywords found in $file"
    echo "   Expected: MUST, SHOULD, MAY, MUST NOT, SHOULD NOT"
    ((issues++))
fi

# Check for non-imperative statements (common anti-patterns)
if grep -qE '(you should|you must|it is recommended|we recommend|consider )' "$file"; then
    echo "⚠️  Non-imperative statements found in $file:"
    grep -nE '(you should|you must|it is recommended|we recommend|consider )' "$file" | head -3
    echo "   Use imperative form: 'MUST do X' not 'you should do X'"
    ((issues++))
fi

# Check for question-style guidance
if grep -qE '\?$' "$file" | grep -qE '(should|could|would)'; then
    echo "⚠️  Question-style guidance found (use imperative statements instead)"
    ((issues++))
fi

# Check file has reasonable structure
if ! grep -qE '^#+ ' "$file"; then
    echo "⚠️  No markdown headers found in $file"
    echo "   AGENTS.md files should have clear section structure"
    ((issues++))
fi

# Summary
if [[ $issues -eq 0 ]]; then
    echo "✅ Agent Rules validation passed for $file"
    exit 0
else
    echo ""
    echo "Found $issues potential issue(s) in $file"
    echo "Review Agent Rules specification: docs/quality/documentation-standards.md"
    exit 0  # Don't fail hook, just warn
fi
