# Claude Code Integration

## .claude/settings.json Configuration

Use `.claude/settings.json` for all Claude Code configuration including permissions and hooks.

## Permission Management

### MUST include in permissions.allow

Safe read-only tools:
- `Tool:Read` - Read files
- `Tool:Grep` - Search in files
- `Tool:Glob` - Find files by pattern
- `Tool:LS` - List directory contents (deprecated, use Glob)
- `Tool:TodoWrite` - Task tracking

Safe bash commands:
- `bash:ls`, `bash:pwd`, `bash:cd`
- `bash:cat`, `bash:head`, `bash:tail`
- `bash:grep`, `bash:find`, `bash:wc`

Read-only git commands:
- `bash:git status`
- `bash:git log`
- `bash:git diff`
- `bash:git show`

Read-only system commands:
- `bash:npm --version`
- `bash:brew list`
- `bash:which`
- `bash:command -v`

Repository-specific utilities:
- `bash:./dotfiles.sh status`
- `bash:shellcheck`

### NEVER include in permissions.allow

Destructive commands:
- `bash:rm`, `bash:mv`, `bash:chmod`
- `bash:git commit`, `bash:git push`
- `bash:npm install`
- `bash:sudo *`
- `bash:brew install`

Commands that modify state without explicit user consent.

### Example safe .claude/settings.json structure

```json
{
  "permissions": {
    "allow": [
      "Tool:Read",
      "Tool:Grep",
      "Tool:Glob",
      "Tool:TodoWrite",
      "bash:git status",
      "bash:git log",
      "bash:git diff",
      "bash:git show",
      "bash:./dotfiles.sh status",
      "bash:shellcheck*",
      "bash:ls*",
      "bash:cat*",
      "bash:pwd",
      "bash:which*",
      "bash:command -v*"
    ],
    "deny": [
      "bash:git commit*--no-gpg-sign*",
      "bash:git commit*-n*",
      "bash:git push*--force*",
      "bash:git push*-f*",
      "bash:rm -rf*",
      "bash:sudo*"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f \"$FILE_PATH\" ] && sed -i '' 's/[[:space:]]*$//' \"$FILE_PATH\" || true",
            "description": "Remove trailing whitespace"
          }
        ]
      }
    ]
  }
}
```

## Hook Configuration

### PostToolUse Hooks

Hooks run automatically after tool use to maintain code quality.

**Whitespace cleanup hook:**
```json
{
  "matcher": "Write|Edit|MultiEdit",
  "hooks": [
    {
      "type": "command",
      "command": "[ -f \"$FILE_PATH\" ] && sed -i '' 's/[[:space:]]*$//' \"$FILE_PATH\" || true",
      "description": "Remove trailing whitespace"
    }
  ]
}
```

**Shellcheck validation hook:**
```json
{
  "matcher": "Write|Edit.*\\.sh$",
  "hooks": [
    {
      "type": "command",
      "command": "command -v shellcheck >/dev/null && shellcheck -x \"$FILE_PATH\" 2>&1 | head -20 || true",
      "description": "Lint shell scripts"
    }
  ]
}
```

### Hook Guidelines

- MUST use PostToolUse hooks for automatic cleanup (whitespace removal, formatting)
- MUST include file existence checks in hook commands
- MUST use safe command patterns that won't fail the hook system
- SHOULD add hooks for common code quality improvements (linting, formatting)
- NEVER add hooks that could corrupt files or cause data loss

### Hook Safety Patterns

```bash
# ✅ GOOD: Check file exists, use || true for safety
[ -f "$FILE_PATH" ] && command "$FILE_PATH" || true

# ✅ GOOD: Check command exists first
command -v tool >/dev/null && tool "$FILE_PATH" || true

# ❌ BAD: No error handling
sed -i '' 's/pattern//' "$FILE_PATH"

# ❌ BAD: Could fail hook system
tool "$FILE_PATH"
```

## Maintenance Guidelines

### MUST update .claude/settings.json when adding new safe utility scripts

When creating new repository-specific commands:
```json
{
  "permissions": {
    "allow": [
      "bash:./dotfiles.sh status",
      "bash:./new-utility.sh"  // Add new safe command
    ]
  }
}
```

### MUST review permissions periodically for security

Regular security review checklist:
- [ ] All allowed commands are truly read-only or safe
- [ ] No user-specific paths or credentials included
- [ ] Malicious arguments cannot cause harm via allowed commands
- [ ] Deny list covers common destructive operations
- [ ] Hook commands cannot be exploited

### SHOULD commit .claude/settings.json to share convenience

Commit settings if:
- All entries are safe for all users
- No user-specific paths or credentials
- Settings improve development workflow

Do NOT commit if:
- Contains user-specific permissions
- Contains experimental/unsafe permissions
- Not tested with fresh Claude sessions

### NEVER add permissions for commands that could cause data loss or security issues

Always consider:
- Could this command delete files?
- Could this command modify files without user consent?
- Could this command leak credentials?
- Could malicious input exploit this permission?

## Security Review Process

### MUST verify all allowed commands are truly read-only or safe

For each allowed command:
1. Test with malicious input
2. Verify cannot delete/modify files
3. Check cannot leak credentials
4. Ensure no privilege escalation

### MUST ensure no user-specific paths or credentials are included

Never in settings.json:
- Personal API keys
- Absolute paths to user directories
- Machine-specific configurations
- Credentials or tokens

### MUST test that malicious arguments cannot cause harm

Test scenarios:
```bash
# Test command injection
bash:git status "; rm -rf /"

# Test path traversal
bash:./dotfiles.sh status "../../../etc/passwd"

# Test privilege escalation
bash:which "sudo rm -rf /"
```

### SHOULD periodically audit permission list for security implications

Regular audit (monthly):
- Review allow list for new vulnerabilities
- Update deny list with newly discovered risks
- Test permissions with security mindset
- Document any security concerns

### MUST validate hook commands cannot be exploited or cause system damage

Hook security checklist:
- [ ] Hook has file existence check
- [ ] Hook uses `|| true` for safety
- [ ] Hook cannot be exploited via $FILE_PATH
- [ ] Hook has timeout protection
- [ ] Hook tested with malicious filenames

## Claude Hooks Integration

For Claude Code hook development and architecture:

**Architecture:** See `claude_hooks/AGENTS.md` for development rules

**Status:** Use `./dotfiles.sh status` to check hook build status

**Quick Reference:**
- Build hooks: `./claude_hooks/build-hooks.sh`
- Hook config: `.claude/settings.json` (already configured)
- Hook output: Visible in Claude Code transcript (Ctrl+R)

### Custom Rust Hooks

This repository includes custom Rust hooks for performance:

**whitespace-cleaner:**
- Removes trailing whitespace from files
- Written in Rust for speed
- Built via `./claude_hooks/build-hooks.sh`
- Configured in `.claude/settings.json`

**Building hooks:**
```bash
# Build all hooks
./claude_hooks/build-hooks.sh

# Check build status
./dotfiles.sh status
```

## Sub-Agent Configuration

Repository includes specialized sub-agents:

**product-manager:** Feature planning and UX oversight
**architecture-assistant:** Code architecture decisions
**shell-validator:** Bash/zsh script validation
**security-auditor:** Security scanning and auditing

See `.claude/agents/README.md` for details.

## Testing Claude Code Configuration

### Test permission changes
```bash
# 1. Edit .claude/settings.json
# 2. Close and reopen Claude Code session
# 3. Test new permissions work as expected
# 4. Test denied operations are blocked
```

### Test hook functionality
```bash
# 1. Edit a file with trailing whitespace
# 2. Save file
# 3. Check whitespace removed
# 4. View transcript (Ctrl+R) for hook output
```

### Test sub-agent delegation
```bash
# Ask Claude: "Review this shell script for security issues"
# Should delegate to security-auditor agent
```

## Cross-References

- claude_hooks/AGENTS.md (Hook development)
- docs/security/patterns.md (Security review)
- .claude/agents/README.md (Sub-agent documentation)
