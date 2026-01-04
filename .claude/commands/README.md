# Repository-Specific Commands

This directory contains slash commands that are **specific to this dotfiles repository**.

These commands only work in this repository and are not stowed globally. They provide dotfiles-specific functionality like system validation and hook log viewing.

## Available Commands

### /validate-dotfiles
**Comprehensive validation of entire dotfiles system**

**Purpose**: One-stop health check for the entire dotfiles repository.

**What it validates:**
1. **Installation Status** - GNU Stow package validation
2. **Version Compliance** - Tools meet versions.config requirements
3. **Hook Build Status** - Claude hooks are built
4. **Security Audit** - Permissions, .gitignore, credentials
5. **Documentation Links** - All markdown links valid
6. **Shell Script Linting** - Shellcheck on all .sh files

**Usage:**
```bash
/validate-dotfiles
```

**When to use:**
- Before committing changes
- After making significant modifications
- Periodically for health checks
- Before releases/tagging

**Exit codes:**
- `0` - All checks passed
- `1` - Warnings (non-critical)
- `2` - Failures (critical)

**See:** `validate-dotfiles.md` for full documentation

---

### /show-hook-log
**View recent Claude Code hook execution logs**

**Purpose**: Shows what hooks have run, when, and their output.

**What it shows:**
- Timestamps of hook executions
- Which hook ran (whitespace-cleaner, shellcheck, validate-agent-rules)
- File paths processed
- Hook output and status

**Usage:**
```bash
/show-hook-log [lines]
```

**Arguments:**
- `lines` - Number of log lines to show (default: 50)

**Log location:** `~/.claude/hook-output.log`

**When to use:**
- Debugging hooks
- Understanding automated changes
- Verifying code quality checks ran
- Troubleshooting unexpected behavior

**See:** `show-hook-log.md` for full documentation

---

### validate-agent-rules.sh
**Validate AGENTS.md files for Agent Rules compliance**

**Purpose**: Utility script that validates AGENTS.md files follow the Agent Rules specification.

**What it validates:**
- RFC 2119 keyword usage (MUST, SHOULD, MAY)
- Imperative statement format (not "you should")
- Clear markdown structure
- Common anti-patterns

**Usage:**
```bash
.claude/commands/validate-agent-rules.sh path/to/AGENTS.md
```

**Used by:**
- PostToolUse hook (automatic validation on AGENTS.md edits)
- documentation-reviewer agent
- Manual documentation audits

**Output example:**
```
✅ Agent Rules validation passed for shell/AGENTS.md
```

Or:
```
⚠️  No RFC 2119 keywords found in shell/AGENTS.md
   Expected: MUST, SHOULD, MAY, MUST NOT, SHOULD NOT
```

**See:** `validate-agent-rules.md` for full documentation

---

## Why Repository-Specific?

These commands are in `.claude/commands/` (not `claude-code/commands/`) because they:
- Only work in this dotfiles repository
- Reference dotfiles-specific files (versions.config, packages.config)
- Validate dotfiles-specific structure (GNU Stow packages)
- Check dotfiles-specific hooks
- Are not useful in other repositories

## Generic Commands

For commands that work in any repository, see:
- `claude-code/commands/README.md` - Generic commands (commit, git-status)
- `/commit` - GPG-signed commits (works anywhere)
- `/git-status` - Formatted git status (works anywhere)

## Related

**Agents:** See `.claude/agents/README.md` for repository-specific agents
**Settings:** See `.claude/settings.json` for permissions and hooks
**Main context:** See `CLAUDE.md` for navigation

---

**Last Updated**: 2026-01-04
**Repository-Specific Commands**: 2
