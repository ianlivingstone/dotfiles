---
description: Generate commit message and commit staged changes
---

# Commit Workflow

Create commits with AI-generated messages and intelligent GPG handling.

## Workflow

**IMPORTANT: Always validate before committing!**

1. **Discover validation approach** for this repository:
   - Check for repository-specific slash commands (e.g., /validate, /test)
   - Read README.md or CONTRIBUTING.md for validation instructions
   - Check for pre-commit hooks (.git/hooks/pre-commit)
   - Look at CI workflows (.github/workflows/*) to understand what checks run

2. **Run appropriate validation** based on what you discover

3. **Only if validation passes**, proceed with commit:

```bash
cat <<'EOF' | ~/.claude/commands/commit.sh commit
Your commit message here

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
```
