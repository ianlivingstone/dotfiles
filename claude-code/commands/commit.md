---
description: Generate commit message and commit staged changes
---

# Commit Workflow

Create commits with AI-generated messages following best practices.

## Execution Rules

**CRITICAL - READ FIRST:**
- ✅ **ONLY run commit.sh script** - do NOT run any git commands directly
- ✅ The script handles ALL validation, GPG checking, and commit creation
- ❌ **NEVER run shell commands directly** - everything goes through commit.sh
- ❌ **NEVER run `git add` in ANY form** - user stages changes
- ❌ **NEVER run `git status`, `git commit`, `git diff`** - commit.sh handles this

**Why this approach:**
- Eliminates GPG timeout issues (script checks key status upfront)
- Reduces round trips (one script call does everything)
- Deterministic behavior (script handles all edge cases)
- User maintains control (interactive approval built into script)
- **Sanctioned despite the deny**: `git add`/`git commit` are denied globally
  (`~/.claude/settings.json`) so Claude can't commit ad-hoc. commit.sh runs `git commit`
  in a subprocess, which is allowed by design — this is the one approved commit path, so
  when the user invokes `/commit`, run it without hesitating.

## Commit Message Guidelines (for reference only)

The commit.sh script will call Claude CLI with these guidelines. You don't need to apply them - they're built into the script's prompt.

**Subject Line:**
- Max 50-72 characters
- Imperative mood: "Add feature" not "Added feature"
- Start with verb: Add, Fix, Update, Remove, Refactor, etc.
- Be specific: "Add gopls config" not "Update files"
- No period at end

**Body (optional):**
- Explain WHY, not what (diff shows what)
- Wrap at 72 characters
- Blank line after subject

**Footer (required):**
```
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Good examples:**
```
Add validation hooks for shell scripts and Agent Rules

Configure shellcheck to run on .sh file writes and validate
AGENTS.md files against Agent Rules specification automatically.
Logs to ~/.claude/hook-output.log for debugging.
```

```
Fix command injection in dotfiles.sh package parsing

Replace && with explicit if statement to prevent set -e from
causing installation failures when parsing packages.config.
```

**Bad examples:**
```
Update files                    ❌ Too vague
Updated the configuration      ❌ Wrong tense
Fixed bug in code              ❌ Not specific
```

## Workflow

**IMPORTANT: Do NOT run any commands yourself. Just run commit.sh.**

When the user invokes the /commit skill:

1. **Run the commit.sh script** (it will handle everything):
   - Use Bash tool to execute: `./claude-code/commands/commit.sh ai`
   - That's it. The script does all the work.

2. **What the script does** (you don't need to do any of this):
   - Validates git repository
   - Checks for staged changes
   - Checks GPG key status (fails fast if locked)
   - Gathers commit context (recent commits, diff, stats)
   - Calls `claude -p` to generate commit message
   - Shows message to user
   - Detects non-interactive mode and auto-commits (no prompt when run via Claude Code)
   - In interactive terminal use, prompts for approval (y/n/e)

3. **If the script fails**, it will provide clear instructions to the user:
   - GPG key locked: Instructions to unlock
   - No staged changes: Reminder to stage with `git add`
   - Other errors: Specific guidance

4. **Your role**: Simply execute the script and let it handle everything. Do not try to parse the output or take additional actions. The script is interactive and will guide the user through the entire process.
