---
description: Generate commit message and commit staged changes
---

# Commit Workflow

Create commits with AI-generated messages and intelligent GPG handling.

## Workflow

**IMPORTANT: The user stages changes, not Claude!**

Claude should NEVER run `git add` commands. The user is responsible for staging their changes.

1. **Check for staged changes** - verify the user has staged files with `git status`

2. **Discover validation approach** for this repository:
   - Check for repository-specific slash commands (e.g., /validate, /test)
   - Read README.md or CONTRIBUTING.md for validation instructions
   - Check for pre-commit hooks (.git/hooks/pre-commit)
   - Look at CI workflows (.github/workflows/*) to understand what checks run

3. **Run appropriate validation** based on what you discover

4. **Only if validation passes**, proceed with commit:

```bash
cat <<'EOF' | ~/.claude/commands/commit.sh commit
Your commit message here

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
```
