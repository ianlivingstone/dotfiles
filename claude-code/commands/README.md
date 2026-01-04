# Dotfiles Slash Commands

This directory contains **generic** slash commands that could be used in any repository.

**IMPORTANT**: This repository has two types of commands:
- **Generic commands** (here: `claude-code/commands/`) - Useful in any repo (commit, git-status)
- **Repository-specific commands** (`.claude/commands/`) - Only for this dotfiles repo (validate-dotfiles, show-hook-log)

## Command Organization

### Generic Commands (this directory)
Commands in `claude-code/commands/` are stowed to `~/.claude/commands/` and available globally:
- `/commit` - GPG-signed commits (works anywhere)
- `/git-status` - Formatted git status (works anywhere)

### Repository-Specific Commands (`.claude/commands/`)
Commands in `.claude/commands/` are only for this dotfiles repository:
- `/validate-dotfiles` - Comprehensive dotfiles validation (dotfiles-specific)
- `/show-hook-log` - View hook logs (dotfiles-specific)
- `validate-agent-rules.sh` - AGENTS.md validation utility (dotfiles-specific)

See [`.claude/commands/README.md`](./.claude/commands/README.md) for repository-specific command documentation.

## What Are Slash Commands?

Slash commands are custom commands that extend Claude Code's functionality. They provide quick access to common operations with consistent, high-quality output.

**How to use:**
```
/command-name [arguments]
```

Commands are invoked with a forward slash and run immediately in the current context.

## Generic Commands (Available Anywhere)

### /commit
**Generate commit messages and create GPG-signed commits**

**Purpose**: Automates the creation of well-formatted, GPG-signed commits following repository conventions.

**What it does:**
1. Runs `git status` and `git diff` to understand changes
2. Reviews recent commit history for message style
3. Generates an appropriate commit message
4. Creates a GPG-signed commit with the message
5. Verifies the commit was successful

**Key Features:**
- Enforces GPG signing (blocks commits without signing)
- Generates contextual commit messages
- Follows repository commit message conventions
- Handles passphrase caching for multiple commits
- Adds co-authorship attribution
- Proper temp file cleanup

**Usage:**
```bash
/commit
```

**Output:**
- Formatted git status showing what will be committed
- Recent commit messages for context
- Generated commit message (for review)
- Commit creation with GPG signature
- Verification of successful commit

**Requirements:**
- Changes must be staged (`git add`)
- GPG key configured for signing
- GPG agent running for passphrase

**See also:** `commit.md` for full documentation

---

### /git-status
**Show formatted git status with actionable sections**

**Purpose**: Provides a clean, organized view of repository status with clear sections and helpful suggestions.

**What it does:**
1. Runs `git status --porcelain` to get current state
2. Organizes output into three sections:
   - Staged changes (ready to commit)
   - Unstaged changes (modified but not staged)
   - Untracked files (new files not in git)
3. Provides actionable suggestions based on state

**Key Features:**
- Beautiful formatted output with sections
- Color-coded status indicators
- Counts of files in each category
- Helpful suggestions (what to do next)
- Empty state handling (clean working tree)

**Usage:**
```bash
/git-status
```

**Output Example:**
```
📊 Repository Status

Staged Changes (2 files):
  M  CLAUDE.md
  M  .claude/settings.json

Unstaged Changes (1 file):
  M  docs/plans/improvement-plan.md

Suggestions:
• Stage changes: git add <file>
• Review changes: git diff
• Create commit: /commit
```

**See also:** `git-status.md` for full documentation

---

## Repository-Specific Commands

For commands specific to this dotfiles repository (not generic), see:
- **[`.claude/commands/README.md`](../../.claude/commands/README.md)** - Repository-specific command documentation
- `/validate-dotfiles` - Comprehensive dotfiles validation
- `/show-hook-log` - View hook execution logs
- `validate-agent-rules.sh` - AGENTS.md validation utility

---

## Commands vs Agents

**When to use commands:**
- Quick, specific operations
- Well-defined tasks with consistent output
- Operations you do frequently
- Tasks that need consistent format

**When to use agents:**
- Complex, multi-step tasks
- Tasks requiring decision-making
- Planning and design work
- Tasks needing context from multiple files

**Available agents:** See `.claude/agents/README.md`

---

## Creating New Commands

### Command Structure

Each command consists of two files:

1. **command-name.md** - Documentation (frontmatter + description)
   ```markdown
   ---
   description: Brief description for command palette
   ---

   Detailed documentation about what the command does,
   how to use it, examples, etc.
   ```

2. **command-name.sh** - Implementation (executable bash script)
   ```bash
   #!/usr/bin/env bash
   # Description of what this script does

   set -euo pipefail

   # Implementation
   ```

### Command Guidelines

**MUST follow these rules:**
- Use `set -euo pipefail` for error handling
- Quote all variables: `"$variable"`
- Validate inputs before use
- Provide clear, actionable output
- Include error messages with suggestions
- Clean up temp files
- Exit with appropriate codes (0=success, 1=warning, 2=error)

**SHOULD follow these practices:**
- Use colors for better readability
- Show progress for multi-step operations
- Provide examples in documentation
- Handle edge cases gracefully
- Test with shellcheck

**Documentation MUST include:**
- Clear description of purpose
- What the command does (step-by-step)
- Usage examples
- Key features
- Requirements/prerequisites
- Exit codes (if non-standard)
- Related commands/agents

### Example: Creating a New Command

**1. Create documentation file:**
```bash
touch claude-code/commands/my-command.md
```

**2. Add frontmatter and docs:**
```markdown
---
description: Does something useful
---

Detailed documentation here...
```

**3. Create implementation:**
```bash
touch claude-code/commands/my-command.sh
chmod +x claude-code/commands/my-command.sh
```

**4. Implement logic:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Your implementation
echo "Doing something useful..."
```

**5. Test:**
```bash
~/.claude/commands/my-command.sh
```

**6. Register (if needed):**
Commands in `claude-code/commands/` are automatically available after `./dotfiles.sh reinstall` (via GNU Stow).

---

## Command Best Practices

### Output Formatting

**Use clear sections:**
```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Section Title"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Use status indicators:**
```bash
echo "✅ Success message"
echo "⚠️  Warning message"
echo "❌ Error message"
echo "ℹ️  Info message"
```

**Use colors sparingly:**
```bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}✅ Success${NC}"
```

### Error Handling

**Check prerequisites:**
```bash
if ! command -v tool &>/dev/null; then
    echo "❌ Error: 'tool' not found"
    echo "Install with: brew install tool"
    exit 1
fi
```

**Validate inputs:**
```bash
file="${1:-}"
if [[ -z "$file" ]]; then
    echo "Usage: $0 <file>"
    exit 1
fi

if [[ ! -f "$file" ]]; then
    echo "❌ Error: File not found: $file"
    exit 1
fi
```

**Provide actionable errors:**
```bash
# ❌ BAD: Vague error
echo "Error: Something failed"

# ✅ GOOD: Actionable error
echo "❌ Error: GPG signing failed"
echo "Check: git config --get user.signingkey"
echo "Fix: export GPG_TTY=\$(tty)"
```

### Security

**Never expose secrets:**
```bash
# ❌ BAD: Echoes password
read -p "Password: " password
echo "Password is: $password"

# ✅ GOOD: Silent read, no echo
read -s -p "Password: " password
# Use password...
unset password  # Clear after use
```

**Validate before executing:**
```bash
# ❌ BAD: Direct user input to command
read -p "File: " file
rm "$file"

# ✅ GOOD: Validate first
read -p "File: " file
if [[ ! "$file" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
    echo "❌ Invalid filename"
    exit 1
fi
rm "$file"
```

---

## Testing Commands

### Manual Testing
```bash
# Test directly
~/.claude/commands/command-name.sh

# Test with arguments
~/.claude/commands/command-name.sh arg1 arg2

# Test error cases
~/.claude/commands/command-name.sh invalid-input
```

### Shellcheck Validation
```bash
shellcheck claude-code/commands/command-name.sh
```

### Integration Testing
```bash
# Test as slash command (requires reinstall)
./dotfiles.sh reinstall
# Then use /command-name in Claude Code
```

---

## Troubleshooting

### Command not found
```bash
# Check if file exists
ls -la ~/.claude/commands/command-name.sh

# Check if symlink is correct
file ~/.claude/commands/command-name.sh

# Reinstall to recreate symlinks
./dotfiles.sh reinstall
```

### Permission denied
```bash
# Make script executable
chmod +x claude-code/commands/command-name.sh

# Verify permissions
ls -la claude-code/commands/command-name.sh
```

### Script errors
```bash
# Run with bash -x for debugging
bash -x ~/.claude/commands/command-name.sh

# Check shellcheck
shellcheck claude-code/commands/command-name.sh
```

---

## References

**Related documentation:**
- `.claude/agents/README.md` - Available agents
- `docs/development/claude-code-integration.md` - Claude Code integration
- `docs/quality/code-standards.md` - Code quality standards
- `CLAUDE.md` - Main context and navigation

**External resources:**
- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [Shellcheck](https://www.shellcheck.net/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

---

**Last Updated**: 2026-01-04
**Commands**: 3 slash commands + 1 utility script
