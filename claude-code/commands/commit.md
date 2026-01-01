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

4. **Draft the commit message** following conventional commit style and repository patterns

5. **Show the commit message to the user and ask for confirmation**:
   - Display the full commit message you've drafted
   - Ask: "Ready to commit with this message? (yes/no/edit)"
   - If "yes": proceed with commit
   - If "no": abort and ask what changes are needed
   - If "edit": ask what modifications to make to the message

6. **Only after user confirms**, proceed with commit:

```bash
# Generate unique filename to avoid race conditions
COMMIT_FILE=$(~/.claude/commands/commit.sh generate-filename)

# Write the commit message to the file
cat > "$COMMIT_FILE" <<'EOF'
Your commit message here

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF

# Commit using the file
~/.claude/commands/commit.sh commit "$COMMIT_FILE"
```
