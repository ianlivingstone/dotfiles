---
description: Comprehensive validation of entire dotfiles system
---

Run comprehensive validation checks on the entire dotfiles system.

This command performs a complete health check including:
- Installation status (Stow validation)
- Version compliance (versions.config requirements)
- Claude Code hooks configured (.claude/settings.json)
- Security audit (permissions, .gitignore coverage)
- Documentation link validation
- Shell script linting (shellcheck)

## Usage

The command runs automatically when invoked:

```bash
/validate-dotfiles
```

## What It Checks

### 1. Installation Status
- Validates all packages using GNU Stow logic
- Reports which packages are properly stowed
- Identifies packages that need changes
- Uses same validation as `./dotfiles.sh status`

### 2. Version Compliance
- Checks all tools against versions.config requirements
- Reports tools that don't meet minimum versions
- Identifies missing tools
- Validates Node.js, Go, Git, Docker, etc.

### 3. Claude Code Hooks
- Checks that `PostToolUse` hooks are configured in `.claude/settings.json`
- Hooks are plain command hooks (no build step / compiled binary)

### 4. Security Audit
- Validates sensitive file permissions (600/700)
- Checks .gitignore coverage for machine-specific files
- Scans for hardcoded credentials (simple patterns)
- Verifies GPG signing configuration
- Checks SSH key permissions

### 5. Documentation Links
- Validates all markdown links in key files
- Checks CLAUDE.md, ARCHITECTURE.md, AGENTS.md
- Validates docs/ directory links
- Tests component AGENTS.md links
- Reports broken internal references

### 6. Shell Script Linting
- Runs shellcheck on all .sh files
- Reports syntax errors and warnings
- Checks dotfiles.sh and shell modules
- Validates command scripts

## Output Format

```
🔍 Comprehensive Dotfiles Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/6] Checking installation status...
✅ All packages properly installed

[2/6] Checking version compliance...
✅ All tools meet minimum versions

[3/6] Checking Claude Code hooks...
✅ PostToolUse hooks configured in .claude/settings.json

[4/6] Running security audit...
✅ Machine configs properly ignored
⚠️  SSH key permissions need fixing: id_rsa (644 should be 600)

[5/6] Validating documentation links...
⚠️  Found 2 broken link(s):
    - CLAUDE.md:45 → docs/missing.md
    - docs/development/test.md:23 → ../nonexistent.md

[6/6] Linting shell scripts...
✅ All shell scripts pass shellcheck

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Passed: 5
⚠️  Warnings: 1
❌ Failed: 0

Recommendations:
1. Run: chmod 600 ~/.ssh/id_rsa
2. Fix broken documentation links
```

## When to Use

**Before committing:**
- Ensures everything is in working state
- Catches issues before they're committed
- Validates documentation is current

**After making changes:**
- Verifies changes didn't break anything
- Checks new files meet standards
- Ensures links still work

**Periodically:**
- Regular health checks
- Catch drift between docs and code
- Identify accumulating technical debt

**Before releases:**
- Comprehensive validation before tagging
- Ensures production-ready state
- Documents any known issues

## Exit Codes

- `0` - All checks passed
- `1` - Warnings found (non-critical)
- `2` - Critical failures found

## Related Commands

- `/git-status` - Show git status
- `/commit` - Create GPG-signed commit
- `./dotfiles.sh status` - Just check installation
- `~/.claude/commands/validate-agent-rules.sh` - Just check documentation

## Notes

- Comprehensive but fast (usually < 10 seconds)
- Non-destructive (only reads, never modifies)
- Can be run anytime without side effects
- Detailed output helps prioritize fixes
- Warnings don't fail the validation (exit 1)
