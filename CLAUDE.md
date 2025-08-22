# Dotfiles Project Context for Claude

This is a bash/shell-based dotfiles management system for macOS using GNU Stow.

**📋 AGENTS.md Compliance**: This file follows the Agent Rules specification for AI coding agents. All sections use imperative statements with RFC 2119 keywords (MUST, SHOULD, MAY) and flat bullet list format for scannable rules.

**📖 For architecture and design principles**: Read [ARCHITECTURE.md](ARCHITECTURE.md)
**📖 For user documentation and features**: Read [README.md](README.md)

This CLAUDE.md focuses on bash-specific development guidance and conventions following Agent Rules format.

## Project Type & Environment

- **Language**: Bash/Zsh shell scripts
- **Platform**: macOS (Darwin)  
- **Package Manager**: GNU Stow for symlink management
- **Shell**: Zsh with modular configuration
- **Security**: GPG signing required, SSH key validation
- **Version Management**: Centralized in `versions.config` with validation
- **Architecture**: Distributed documentation in per-directory `AGENTS.md` files

## Key Commands for Development

```bash
# Test changes
./dotfiles.sh status          # Validates all packages using Stow logic
./dotfiles.sh reinstall       # Safe way to test package changes

# Debug shell modules
source shell/module.sh        # Test individual modules
echo $SHELL_DIR              # Check path resolution

# Dependency management
./dotfiles.sh install         # Checks all dependencies including Docker 28+
./dotfiles.sh update          # Updates Node.js, Go versions from versions.config

# Add new packages
echo "mypackage" >> packages.config  # Default target (~/)
echo "mypackage:$XDG_CONFIG_DIR/mypackage" >> packages.config  # Custom target
```

## Development Patterns

For detailed development patterns and implementation guidelines:

- **🐚 Shell Development**: See [`shell/AGENTS.md`](shell/AGENTS.md) for bash/zsh patterns, path resolution, error handling
- **📦 Package Management**: See [`shell/AGENTS.md`](shell/AGENTS.md) for GNU Stow patterns and validation
- **🔐 Security Patterns**: See [`shell/AGENTS.md`](shell/AGENTS.md) for credential handling, input validation
- **📋 Version Management**: See [`shell/AGENTS.md`](shell/AGENTS.md) for centralized version requirements

## macOS-Specific Considerations

### Homebrew Integration
```bash
# ✅ Check for Homebrew tools
if ! command -v tool &> /dev/null; then
    echo "Install with: brew install tool"
fi

# ✅ macOS hostname commands
hostname -s              # Short hostname
scutil --set HostName    # Set system hostname
```

### XDG Directory Handling
```bash
# ✅ macOS-compatible XDG paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
```

### Security on macOS
```bash
# ✅ Secure curl pattern (enforced throughout project)
SECURE_CURL="curl --proto '=https' --tlsv1.2"

# ✅ File permissions
chmod 700 ~/.gnupg       # GPG directory
chmod 600 config-file    # Private configs
mkdir -p ~/.ssh/sockets && chmod 700 ~/.ssh/sockets
```

## Testing Patterns

### Manual Testing
```bash
# Test individual modules
source shell/security.sh && validate_key_security

# Test package status
./dotfiles.sh status

# Fresh installation test
rm -rf ~/.local/share/nvim && nvim  # Auto-bootstraps
```

### Validation Checks
```bash
# ✅ Always validate before proceeding
if ! validate_key_security; then
    echo "Security validation failed"
    return 1
fi
```

## Debug Commands

```bash
# Shell module debugging
set -x                   # Enable debug output
source shell/module.sh   # Test module loading

# Stow debugging
stow --verbose --no --restow package  # Dry run with details

# Environment debugging
env | grep DOTFILES     # Check cache variables
echo $PATH | tr ':' '\n'  # Check PATH entries
```

## Security Development Guidelines

For detailed security patterns and implementation:
- **🔐 Security Architecture**: See [`shell/AGENTS.md`](shell/AGENTS.md) for comprehensive security patterns, credential handling, input validation, and permission management

## Version Management

For centralized version management architecture:
- **📋 Version Management**: See [`shell/AGENTS.md`](shell/AGENTS.md) for centralized version requirements, validation patterns, and shell module integration

## Documentation Architecture

This project uses **distributed architecture documentation** following Agent Rules specification.

### Agent Rules Compliance for Documentation
- MUST follow Agent Rules specification for all AI agent guidance files
- MUST use imperative statements with RFC 2119 keywords (MUST, SHOULD, MAY, NEVER)
- MUST use flat bullet list format for scannable rules
- MUST keep documentation current with code changes
- SHOULD reference detailed documentation files rather than duplicating content

### Architecture File Structure
```
├── AGENTS.md                   # Agent Rules compliant quick reference
├── ARCHITECTURE.md             # High-level project architecture (Agent Rules format)
├── CLAUDE.md                   # Claude-specific guidelines (Agent Rules format)
├── shell/AGENTS.md             # Shell configuration architecture
├── nvim/AGENTS.md              # Neovim configuration architecture  
├── git/AGENTS.md               # Git configuration architecture
├── ssh/AGENTS.md               # SSH configuration architecture
├── tmux/AGENTS.md              # Tmux configuration architecture
├── claude_hooks/AGENTS.md      # Claude Code hooks architecture
└── [component]/AGENTS.md       # Component-specific architecture
```

### Documentation Maintenance Rules

#### When Making Changes
- MUST update the component's `AGENTS.md` file when modifying that component
- MUST update integration sections in related component `AGENTS.md` files for cross-component changes
- MUST update `ARCHITECTURE.md` for high-level architectural changes
- MUST verify all documentation links still work after changes
- SHOULD include code examples that follow established patterns

#### Agent Rules Format Requirements
- MUST use imperative statements (e.g., "Update the file" not "You should update the file")
- MUST use RFC 2119 keywords for clarity (MUST, SHOULD, MAY, NEVER)
- MUST structure as flat bullet lists for scannability
- MUST be concise and actionable
- SHOULD reference comprehensive documentation files for details

#### Documentation Standards
- MUST answer: Why was this architectural choice made?
- MUST document: How does it integrate with other components?
- MUST include: Key patterns and conventions
- MUST specify: When to follow specific patterns
- MUST identify: Integration points and dependencies
- NEVER include: Outdated examples that don't match current codebase
- NEVER create: Generic documentation that could apply to any project

## Security Issues Reference

For current security issues and fixes:
- **⚠️ Security Issues**: See [`shell/AGENTS.md`](shell/AGENTS.md) for critical command injection fixes, permission patterns, and safety mode requirements

## Code Quality Standards

- **Always quote variables**: `"$variable"`
- **Use explicit returns**: `return 0` for success, `return 1` for failure
- **Check dependencies**: Verify tools exist before using
- **Graceful degradation**: Handle missing tools/configs
- **Consistent error messages**: Use same format/colors
- **Performance first**: Avoid expensive operations in shell startup
- **Security first**: Validate input, secure credentials, audit actions

## Claude Code Configuration Management

### .claude/settings.json Configuration

Use `.claude/settings.json` for all Claude Code configuration including permissions and hooks.

**MUST include in permissions.allow:**
- Safe read-only tools (tool:Read, tool:Grep, tool:Glob, tool:LS, tool:TodoWrite)
- Safe bash commands (bash:ls, bash:pwd, bash:cd, bash:cat, bash:head, bash:tail)
- Read-only git commands (bash:git status, bash:git log, bash:git diff)
- Read-only system commands (bash:npm --version, bash:brew list)
- Repository-specific utilities (bash:./dotfiles.sh status, bash:~/tmux.sh get_battery_status)

**NEVER include in permissions.allow:**
- Destructive commands (bash:rm, bash:mv, bash:chmod)
- Write operations (bash:git commit, bash:git push, bash:npm install)
- System modification commands (bash:sudo *, bash:brew install)
- Commands that modify state without explicit user consent

**Example safe .claude/settings.json structure:**
```json
{
  "permissions": {
    "allow": [
      "tool:Read", "tool:Grep", "tool:Glob", "tool:LS", "tool:TodoWrite",
      "bash:git status", "bash:git log", "bash:git diff",
      "bash:tmux list-*", "bash:tmux show-*",
      "bash:./dotfiles.sh status",
      "bash:npm --version", "bash:brew list"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f \"$FILE_PATH\" ] && sed -i '' 's/[[:space:]]*$//' \"$FILE_PATH\" || true"
          }
        ]
      }
    ]
  }
}
```

**Hook Guidelines:**
- MUST use PostToolUse hooks for automatic cleanup (whitespace removal, formatting)
- MUST include file existence checks in hook commands
- MUST use safe command patterns that won't fail the hook system
- SHOULD add hooks for common code quality improvements (linting, formatting)
- NEVER add hooks that could corrupt files or cause data loss

**Maintenance Guidelines:**
- MUST update .claude/settings.json when adding new safe utility scripts
- MUST review permissions periodically for security
- SHOULD commit .claude/settings.json to share convenience with other users (if all entries are safe)
- NEVER add permissions for commands that could cause data loss or security issues
- MUST test .claude/settings.json changes with fresh Claude sessions

**Security Review Process:**
- MUST verify all allowed commands are truly read-only or safe
- MUST ensure no user-specific paths or credentials are included
- MUST test that malicious arguments cannot cause harm via allowed commands
- SHOULD periodically audit permission list for security implications
- MUST validate hook commands cannot be exploited or cause system damage

## Claude Code Hooks Integration

For Claude Code hook development and architecture:

- **🏗️ Architecture**: See `claude_hooks/AGENTS.md` for development rules
- **🔧 Status**: Use `./dotfiles.sh status` to check hook build status

**Quick Reference:**
- Build hooks: `./claude_hooks/build-hooks.sh`
- Hook config: `.claude/settings.json` (already configured)
- Hook output: Visible in Claude Code transcript (Ctrl+R)

This project prioritizes security, performance, and maintainability in a bash/macOS environment using GNU Stow for configuration management.