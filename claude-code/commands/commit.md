---
description: Generate commit message and commit staged changes
---

# Commit Workflow

Create commits with AI-generated messages following best practices.

## Execution Rules

**CRITICAL - READ FIRST:**
- ✅ Timeout: 5000ms (5 seconds) maximum
- ✅ Run in FOREGROUND (script handles GPG intelligently)
- ✅ Single git commit command (no multi-step workflow)
- ❌ **NEVER, EVER run `git add` in ANY form** (user stages changes)
- ❌ NEVER commit without showing message and getting user approval first

**Forbidden git add commands (ALL BLOCKED):**
- ❌ `git add -A`
- ❌ `git add .`
- ❌ `git add -u`
- ❌ `git add <file>`
- ❌ Any variation of git add

**Why:** User must control what gets staged. Claude staging files could accidentally include secrets, credentials, or unwanted changes.

## Commit Message Template

```
<imperative verb> <what changed> [scope]

[Optional: 1-2 sentence explanation of WHY this change was made]
[Optional: Key technical details if not obvious from diff]

[Optional: Breaking changes, migration notes, or related issues]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Commit Message Ground Rules

**Subject Line (First Line):**
- ✅ Max 50-72 characters
- ✅ Imperative mood: "Add feature" not "Added feature" or "Adds feature"
- ✅ Start with verb: Add, Fix, Update, Remove, Refactor, Document, etc.
- ✅ Be specific: "Add gopls config" not "Update files"
- ✅ No period at end
- ❌ NEVER use vague words: "changes", "updates", "improvements", "fixes"

**Body (Optional):**
- ✅ Explain WHY, not what (diff shows what)
- ✅ Wrap at 72 characters
- ✅ Blank line after subject
- ✅ Use bullet points for multiple items
- ❌ NEVER describe HOW (code shows how)

**Examples of GOOD commits:**
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

```
Remove deprecated tmux mouse-mode options

Options removed in tmux 2.1+. Modern mouse option covers all cases.
```

**Examples of BAD commits:**
```
Update files                    ❌ Too vague
Updated the configuration      ❌ Wrong tense
feat: add new feature          ❌ Redundant prefix (unless repo uses conventional commits)
Fixed bug in code              ❌ Not specific
Changes to improve things      ❌ Meaningless filler
```

## Workflow

**Step 1: Verify staged changes**
```bash
git status
```
If nothing staged, STOP and ask user to stage changes.

**Step 2: Draft commit message**
- Follow template above
- Match repository style (check recent commits)
- Focus on WHAT and WHY
- Be concise but informative

**Step 3: Show message and get user approval (REQUIRED)**

**⚠️  CRITICAL: ALWAYS show the full commit message to the user and wait for approval before running git commit.**

Display the complete commit message in a code block, then ask:
> "Ready to commit with this message? (yes/no/edit)"

**Response handling:**
- **"yes"** → Proceed to Step 4
- **"no"** → Abort, ask what should change
- **"edit"** → Ask for specific changes, revise message, show again for approval

**NEVER skip this step. User must explicitly approve the message.**

**Step 4: Commit in single command (only after approval)**
```bash
git commit -S -m "$(cat <<'EOF'
<subject line>

<optional body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**IMPORTANT:**
- Single bash invocation (no temp files)
- Heredoc preserves formatting
- Script handles GPG intelligently
- Max 5s timeout
