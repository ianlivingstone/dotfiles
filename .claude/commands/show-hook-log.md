---
description: View recent Claude Code hook execution logs
---

Display recent execution logs from Claude Code PostToolUse hooks.

This command shows what hooks have run, when they ran, and their output, providing transparency into automated code quality processes.

## Usage

```bash
/show-hook-log [lines]
```

**Arguments:**
- `lines` - Number of log lines to show (default: 50)

## What It Shows

The hook log captures:
- **Timestamp** - When the hook executed
- **Hook type** - Which hook ran (whitespace-cleaner, shellcheck, validate-agent-rules)
- **File path** - What file was being processed
- **Output** - What the hook reported
- **Status** - Success or failure

## Log Location

Logs are stored in: `~/.claude/hook-output.log`

## Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Claude Code Hook Execution Log
Last 50 lines
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[2026-01-04 14:32:15] whitespace-cleaner
  File: /Users/ian/dotfiles/CLAUDE.md
  Output: Removed trailing whitespace from 3 lines

[2026-01-04 14:35:22] shellcheck
  File: /Users/ian/dotfiles/dotfiles.sh
  Output: ✅ No issues found

[2026-01-04 14:38:45] validate-agent-rules
  File: /Users/ian/dotfiles/shell/AGENTS.md
  Output: ✅ Agent Rules validation passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 3 hook executions shown
Log file: ~/.claude/hook-output.log
```

## Use Cases

**Debugging hooks:**
- See if hooks are actually running
- Check what hooks are doing to your files
- Debug hook failures

**Transparency:**
- Understand automated changes to your code
- Verify code quality checks are running
- See what was automatically fixed

**Troubleshooting:**
- Find out why a file edit behaved unexpectedly
- Check if shellcheck is catching issues
- Verify documentation validation is working

## Examples

**View last 50 lines (default):**
```bash
/show-hook-log
```

**View last 100 lines:**
```bash
/show-hook-log 100
```

**View all logs:**
```bash
/show-hook-log 1000
```

## Log Rotation

The log file automatically rotates when it exceeds 10,000 lines:
- Current log: `~/.claude/hook-output.log`
- Rotated log: `~/.claude/hook-output.log.old`

This prevents unbounded growth while preserving history.

## Manual Log Management

**View log directly:**
```bash
tail -50 ~/.claude/hook-output.log
```

**Clear log:**
```bash
> ~/.claude/hook-output.log
```

**Search log:**
```bash
grep "shellcheck" ~/.claude/hook-output.log
```

## Related

- `.claude/settings.json` - Hook configuration
- `claude_hooks/` - Custom Rust hooks
- `/validate-dotfiles` - Comprehensive validation

## Notes

- Logs are local to your machine only
- Not committed to git (.gitignore)
- Minimal performance impact
- Useful for debugging and transparency
- Shows both automatic fixes and validation results
