---
description: Generate commit message and commit staged changes
---

# Auto-Commit with Generated Message

You are a commit message generator. Your task is to analyze git changes, create a commit message, and run the commit.

## Instructions

1. **Validate commit state:**
   - Run: `~/.claude/commands/commit.sh validate`
   - This script checks for:
     - Git repository exists
     - Staged changes exist
     - No unstaged changes (clean working tree)
   - If validation fails, the script will provide clear error messages and exit
   - The script output will guide the user on how to fix any issues

2. **Analyze recent commits for style:**
   - Run: `~/.claude/commands/commit.sh recent-commits`
   - Observe the commit message style (prefixes, format, length)

3. **Analyze the staged changes:**
   - Run: `~/.claude/commands/commit.sh staged-diff`
   - Run: `~/.claude/commands/commit.sh staged-stats`
   - Identify the primary purpose: new feature, bug fix, refactor, docs, etc.
   - Note the scope: which files/components are affected
   - Understand the "why" behind the changes

4. **Generate the commit message:**
   - First line: concise summary (50-72 chars max)
   - Use imperative mood: "Add feature" not "Added feature"
   - Match the repository's commit style (if it uses prefixes like "feat:", "fix:", use them)
   - Be specific but brief: "Add gopls to dotfiles" not "Update files"
   - Focus on WHAT and WHY, not HOW
   - Add detailed explanation if needed (after blank line)

5. **Create the commit:**
   - Write commit message to a temp file at `/tmp/claude-commit-msg.txt`
   - The message MUST include this footer (after blank line):
     ```
     🤖 Generated with [Claude Code](https://claude.com/claude-code)

     Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
     ```
   - Run: `~/.claude/commands/commit.sh commit /tmp/claude-commit-msg.txt`
   - The script will create the commit and show the result
   - Clean up the temp file: `rm /tmp/claude-commit-msg.txt`

## Commit Message Format

```
<summary line - max 72 chars>

<optional detailed explanation>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Example Good Commit Messages

- `feat: Add SSH keychain integration and restructure hooks`
- `fix: Make security validation non-blocking for shell startup`
- `refactor: Consolidate core system tools check in status`
- `docs: Update AGENTS.md with security patterns`
- `Add gopls as managed dependency with auto-install`

## Rules

- NEVER commit if there are no staged changes
- NEVER commit if there are unstaged changes (must have a clean working tree)
- NEVER include "Updated" or "Changed" without specifying what
- NEVER use vague terms like "various fixes" or "improvements"
- NEVER exceed 72 characters on the first line
- ALWAYS include the Claude Code attribution footer
- DO match the existing commit style from git log
- DO be specific about what changed
- DO explain why if it's not obvious from the what

Now analyze the staged changes and create the commit.
