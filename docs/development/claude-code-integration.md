# Claude Code Integration

## .claude/settings.json Configuration

Use `.claude/settings.json` for all Claude Code configuration including permissions and hooks.

## Permission Management

### Permission rule syntax

Claude Code permission rules take one of two forms:

- **Whole tool:** just the tool name, e.g. `Read`, `Grep`, `Glob`.
- **Bash command:** `Bash(<command prefix>:*)` for prefix matching, e.g. `Bash(git status:*)`.

> ⚠️ The legacy colon forms `Tool:Read` and `bash:git status*` are **no longer
> valid**. Claude Code silently skips them in `allow` rules and `/doctor` reports
> each one as an error. Always use the parenthesized form above.
>
> The `:*` suffix must be at the **end** of the pattern. To match a flag that can
> appear anywhere in the command (deny rules only — see below), use a bare `*`
> wildcard instead, e.g. `Bash(git push*--force*)`, with no trailing `:*`.

### MUST include in permissions.allow

Safe read-only tools (allow the whole tool):
- `Read` - Read files
- `Grep` - Search in files
- `Glob` - Find files by pattern
- `TodoWrite` - Task tracking

Safe bash commands (prefix match):
- `Bash(ls:*)`, `Bash(pwd:*)`, `Bash(cd:*)`
- `Bash(cat:*)`, `Bash(head:*)`, `Bash(tail:*)`
- `Bash(grep:*)`, `Bash(find:*)`, `Bash(wc:*)`

Read-only git commands:
- `Bash(git status:*)`
- `Bash(git log:*)`
- `Bash(git diff:*)`
- `Bash(git show:*)`

Read-only system commands:
- `Bash(which:*)`
- `Bash(command -v:*)`

Repository-specific utilities:
- `Bash(./dotfiles.sh status:*)`
- `Bash(shellcheck:*)`

### NEVER include in permissions.allow

Destructive commands (these belong in `deny`, not `allow`):
- `Bash(rm -rf:*)`, `Bash(chmod 777:*)`
- `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git push:*)`
- `Bash(sudo:*)`

Commands that modify state without explicit user consent.

> **Direct commits are denied.** `.claude/settings.json` (and the global `~/.claude`
> settings) deny `Bash(git commit:*)`, `Bash(git add:*)`, and force-push, so Claude
> can't commit/stage ad-hoc — `deny` overrides `allow` and any instructions. The ONE
> sanctioned commit path is the `/commit` skill (`claude-code/commands/commit.sh`),
> which runs `git commit` in a subprocess; that's allowed by design, since the deny
> only intercepts top-level Bash commands.

### Example safe .claude/settings.json structure

```json
{
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git show:*)",
      "Bash(./dotfiles.sh status:*)",
      "Bash(shellcheck:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(pwd:*)",
      "Bash(which:*)",
      "Bash(command -v:*)"
    ],
    "deny": [
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git push*--force*)",
      "Bash(git push*-f*)",
      "Bash(rm -rf:*)",
      "Bash(sudo:*)"
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

Hooks run automatically after tool use to maintain code quality. The matcher matches
the **tool name** (`Write`, `Edit`, `MultiEdit`) — it can't filter by file path, so do
that in the command. The file path comes from **JSON on stdin** via `jq` (there is no
`$FILE_PATH` env var).

**Whitespace cleanup hook:**
```json
{
  "matcher": "Write|Edit|MultiEdit",
  "hooks": [
    {
      "type": "command",
      "command": "f=$(jq -r '.tool_input.file_path // empty'); [ -n \"$f\" ] && [ -f \"$f\" ] && sed -i '' 's/[[:space:]]*$//' \"$f\" || true",
      "description": "Remove trailing whitespace"
    }
  ]
}
```

**Shell syntax-check hook** (use `zsh -n`, not shellcheck — shellcheck doesn't support zsh):
```json
{
  "matcher": "Write|Edit|MultiEdit",
  "hooks": [
    {
      "type": "command",
      "command": "f=$(jq -r '.tool_input.file_path // empty'); case \"$f\" in *.sh|*.zsh) zsh -n \"$f\" ;; esac",
      "description": "Syntax-check shell scripts"
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
      "Bash(./dotfiles.sh status:*)",
      "Bash(./new-utility.sh:*)"  // Add new safe command
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

Test scenarios (verify each allowed rule cannot be abused via arguments):
```bash
# Test command injection against Bash(git status:*)
git status "; rm -rf /"

# Test path traversal against Bash(./dotfiles.sh status:*)
./dotfiles.sh status "../../../etc/passwd"

# Test privilege escalation against Bash(which:*)
which "sudo rm -rf /"
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

## Claude Code Hooks

Hooks are plain `PostToolUse` command hooks in `.claude/settings.json` — **no build
step, no compiled binary**. Each reads the tool input (JSON on stdin) and acts on the
written/edited file:

- **whitespace-cleaner** — strips trailing whitespace with `sed`.
- **zsh -n** — syntax-checks `*.sh`/`*.zsh` files (shellcheck doesn't support zsh).
- **validate-agent-rules** — runs `.claude/commands/validate-agent-rules.sh` on `AGENTS.md`.

Each hook extracts the path with `jq -r '.tool_input.file_path'` and filters to the file
it cares about; output is appended to `~/.claude/hook-output.log` (view via the
`show-hook-log` command).

> **Hooks receive input as JSON on stdin** — parse it with `jq`. Do NOT rely on
> `$FILE_PATH` / `$CLAUDE_FILE_PATHS` env vars; current Claude Code does not set them
> (an earlier API did, which is why the previous Rust hook silently no-op'd).

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

- docs/security/patterns.md (Security review)
- .claude/agents/README.md (Sub-agent documentation)
