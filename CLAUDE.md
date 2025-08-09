# Dotfiles Project Context for Claude

This is a bash/shell-based dotfiles management system for macOS using GNU Stow. 

**📖 For architecture and design principles**: Read [ARCHITECTURE.md](ARCHITECTURE.md)
**📖 For user documentation and features**: Read [README.md](README.md)

This CLAUDE.md focuses on bash-specific development guidance and conventions.

## Project Type & Environment

- **Language**: Bash/Zsh shell scripts
- **Platform**: macOS (Darwin)  
- **Package Manager**: GNU Stow for symlink management
- **Shell**: Zsh with modular configuration
- **Security**: GPG signing required, SSH key validation

## Key Commands for Development

```bash
# Test changes
./dotfiles.sh status          # Validates all packages using Stow logic
./dotfiles.sh reinstall       # Safe way to test package changes

# Debug shell modules
source shell/module.sh        # Test individual modules
echo $SHELL_DIR              # Check path resolution

# Add new packages
echo "mypackage" >> packages.config  # Default target (~/)
echo "mypackage:$XDG_CONFIG_DIR/mypackage" >> packages.config  # Custom target
```

## Bash/Shell Development Patterns

### Path Resolution (Critical)
```bash
# ✅ ALWAYS use this pattern for shell modules
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")" && pwd)"
source "$SHELL_DIR/utils.sh"

# ✅ Use utility functions
get_shell_dir()          # Portable path resolution with symlinks
get_xdg_config_dir()     # Consistent XDG directory handling
```

### Config File Loading
```bash
# ✅ Standard pattern for loading config files
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    line=$(eval echo "$line")  # Expand variables
    ARRAY+=("$line")
done < "config-file"

# ✅ Use readarray alternative (compatible with older bash)
# Never use readarray - not available on all systems
```

### Environment Variable Caching
```bash
# ✅ Session-scoped caching pattern
if [[ "$DOTFILES_CACHE_VAR" != "1" ]]; then
    expensive_operation
    export DOTFILES_CACHE_VAR=1  # Cache for child processes
fi
```

### Error Handling & Shell Safety Modes
```bash
# ✅ Installation scripts (dotfiles.sh) - STRICT MODE
#!/usr/bin/env zsh
set -euo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR

# ✅ Shell modules (shell/*.sh) - NO set -e (they're sourced)
#!/usr/bin/env zsh
# NO set -e! Would kill the shell if sourced
# Use return instead of exit

# ✅ Safe variable expansion
"$variable"              # Always quote
"${variable:-default}"   # With defaults
[[ -n "${variable:-}" ]] # Safe undefined variable check

# ✅ Safe file operations with proper error handling
if [[ -f "$file" ]]; then
    source "$file" || {
        echo "Failed to source $file" >&2
        return 1  # return in sourced scripts, exit in executed scripts
    }
else
    echo "Config not found: $file" >&2
fi
```

### Shell Safety Mode Guidelines

**For Installation Scripts (`dotfiles.sh`):**
```bash
#!/usr/bin/env zsh
set -euo pipefail  # Strict mode: exit on error, undefined vars, pipe failures
trap 'echo "❌ Installation failed at line $LINENO: $BASH_COMMAND" >&2' ERR

# Installation must fail-fast to prevent partial configuration
```

**For Shell Modules (`shell/*.sh` - sourced files):**
```bash
#!/usr/bin/env zsh
# NEVER use set -e in sourced scripts - would kill the shell!
# Use graceful error handling instead

# ✅ Graceful degradation pattern
load_optional_tool() {
    if command -v tool &>/dev/null; then
        setup_tool
        return 0
    else
        show_warning "Tool not available, skipping"
        return 1  # Use return, not exit!
    fi
}
```

**For Main Shell RC (`.zshrc`):**
```bash
# ✅ Validation with safe exit (current pattern is excellent)
if ! source "$SHELL_DIR/security.sh" || ! validate_key_security; then
    echo "🚨 Security validation failed"
    return 1  # return kills script loading, not shell
fi
```

### Package Management Pattern
```bash
# ✅ Stow-based validation (don't reinvent)
stow_output=$(stow --no --verbose --restow --target="$target" "$package" 2>&1)
exit_code=$?

# Interpret Stow's response instead of guessing
if [[ $exit_code -eq 0 && -z "$stow_output" ]]; then
    echo "✅ properly stowed"
elif [[ "$stow_output" =~ "reverts previous action" ]]; then
    echo "✅ properly stowed" # Would update existing links
else
    echo "❌ needs attention: $stow_output"
fi
```

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

## Shell Module Development Rules

### Module Structure Template
```bash
#!/usr/bin/env zsh
# Module description
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Source shared utilities (ALWAYS first)
SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")" && pwd)"
source "$SHELL_DIR/utils.sh"

# Module logic here - use return (not exit) for error handling
```

### Loading Order Dependencies
1. `utils.sh` - Must be first (provides shared functions)
2. `core.sh` - Basic shell setup
3. `aliases.sh` - Command shortcuts  
4. `languages.sh` - Programming environments
5. `functions.sh` - Status and utilities
6. `security.sh` - Key validation (runs before agents)
7. `agents.sh` - SSH/GPG agents
8. `prompt.sh` - Shell prompt (last)

### Performance Rules
```bash
# ✅ Fast filesystem checks
[[ -d "$version_dir" ]]          # Fast
command -v tool >/dev/null       # Fast

# ❌ Slow command execution during shell startup
tool --version                   # Slow - avoid in startup
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

## Common Gotchas & Solutions

### Shell Compatibility
- **Never use `readarray`** - not available on all systems
- **Use `[[ ]]` instead of `[ ]`** for conditionals
- **Quote all variables**: `"$var"` not `$var`
- **Use portable shebang**: `#!/usr/bin/env zsh`

### GNU Stow Gotchas  
- **Always use `--target`** for custom destinations
- **Use `--restow`** instead of separate unstow/stow
- **Check exit codes** - Stow can succeed but warn

### macOS Path Issues
- **Use absolute paths** in scripts - `$HOME/path` not `~/path`
- **Handle spaces in paths** - always quote: `"$HOME/My Documents"`
- **Use portable commands** - `hostname -s` works across Unix systems

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

## macOS Shell Security Best Practices

### Credential Security
```bash
# ✅ Secure credential input (only for actual secrets like passphrases)
read_credential_securely() {
    local prompt="$1" varname="$2"
    set +H  # Disable history expansion
    stty -echo
    printf "%s: " "$prompt"
    read -r "$varname"
    stty echo
    printf "\n"
}

# ✅ Clean up sensitive variables (NOT for public data like git name/email)
cleanup_credentials() {
    for var in SSH_PASSPHRASE GPG_PASSPHRASE API_KEYS; do
        unset "$var" 2>/dev/null || true
    done
}

# ℹ️ Note: Git name/email are public data (visible in commits) - regular read -p is fine
```

### Network Security
```bash
# ✅ Enhanced secure download with validation
secure_download() {
    local url="$1" output="$2"
    
    # Validate HTTPS-only
    [[ ! "$url" =~ ^https:// ]] && return 1
    
    curl --proto '=https' --tlsv1.2 \
         --fail --silent --show-error \
         --max-time 30 --connect-timeout 10 \
         --output "$output" "$url"
}

# ✅ Secure curl pattern (already implemented in project)
SECURE_CURL="curl --proto '=https' --tlsv1.2"
```

### Input Validation & Command Injection Prevention
```bash
# ✅ CRITICAL: Replace eval with safe variable expansion
# ❌ NEVER use eval on user input:
line=$(eval echo "$line")  # DANGEROUS - allows command execution

# ✅ Safe variable expansion patterns:
target="${target/#\~/$HOME}"                    # Replace leading ~
target="${target//\$HOME/$HOME}"                # Replace $HOME
target="${target//\$XDG_CONFIG_DIR/$XDG_CONFIG_DIR}"  # Replace XDG vars

# ✅ Sanitize user input by type (for validation, not security)
sanitize_input() {
    local input="$1" type="$2"
    case "$type" in
        "hostname") [[ "$input" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]] ;;
        "email") [[ "$input" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] ;;
        "gpg_key") [[ "$input" =~ ^[A-F0-9]{8,40}$ ]] ;;
        "path") [[ "$input" =~ ^[[:print:]]*$ && "$input" != *$'\n'* ]] ;;
    esac
}

# ✅ Safe command execution
safe_command() {
    local cmd="$1"; shift
    command -v "$cmd" >/dev/null 2>&1 || return 1
    "$cmd" "$@"  # Explicit argument separation prevents injection
}
```

### File System Security
```bash
# ✅ Secure temporary files
create_secure_temp() {
    local prefix="$1"
    local temp_file=$(mktemp -t "${prefix}.XXXXXXXX") || return 1
    chmod 600 "$temp_file"
    trap "rm -f '$temp_file'" EXIT INT TERM
    echo "$temp_file"
}

# ✅ Path traversal prevention
validate_path_safety() {
    local path="$1" base_dir="$2"
    local real_path=$(realpath "$path" 2>/dev/null) || return 1
    local real_base=$(realpath "$base_dir" 2>/dev/null) || return 1
    [[ "$real_path" == "$real_base"* ]]
}

# ✅ Enforce secure file permissions
secure_file_permissions() {
    local file="$1" expected_perms="$2"
    local current_perms=$(stat -f "%OLp" "$file" 2>/dev/null)
    [[ "$current_perms" != "$expected_perms" ]] && chmod "$expected_perms" "$file"
}
```

### macOS-Specific Security Features
```bash
# ✅ Keychain integration for SSH
# Add to SSH config: UseKeychain yes, AddKeysToAgent yes
ssh-add --apple-load-keychain 2>/dev/null || true

# ✅ Dynamic tool detection (avoid hardcoding paths)
detect_best_pinentry() {
    local pinentry_program=""
    for program in pinentry-curses pinentry-tty pinentry; do
        if command -v "$program" &>/dev/null; then
            pinentry_program=$(command -v "$program")
            break
        fi
    done
    echo "${pinentry_program:-}"  # Return path or empty
}

# ✅ Enhanced SSH key validation
validate_ssh_key_strength() {
    local key_path="$1"
    local key_type=$(ssh-keygen -l -f "$key_path" 2>/dev/null | awk '{print $4}' | tr -d '()')
    local key_bits=$(ssh-keygen -l -f "$key_path" 2>/dev/null | awk '{print $1}')
    
    case "$key_type" in
        "RSA") [[ "$key_bits" -ge 3072 ]] ;;  # Minimum 3072 bits
        "DSA") return 1 ;;                    # DSA deprecated
        "Ed25519"|"ECDSA") return 0 ;;        # Modern algorithms OK
        *) return 1 ;;                        # Unknown/unsafe
    esac
}
```

### Security Logging & Auditing
```bash
# ✅ Security event logging
security_log() {
    local level="$1" message="$2"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    local logfile="$HOME/.local/share/dotfiles/security.log"
    
    mkdir -p "$(dirname "$logfile")"
    echo "[$timestamp] [$level] $message" >> "$logfile"
    
    # Rotate log (keep last 1000 lines)
    tail -n 999 "$logfile" > "$logfile.tmp" && mv "$logfile.tmp" "$logfile"
}
```

### Process Security
```bash
# ✅ Process isolation for sensitive operations
secure_exec() {
    local cmd="$1"; shift
    # Clean environment with only essential variables
    env -i HOME="$HOME" PATH="/usr/bin:/bin" SHELL="$SHELL" "$cmd" "$@"
}

# ✅ Avoid credential exposure in process lists
# Use read_credential_securely() instead of command-line arguments
```

## Security Checklist for New Code

- [ ] **Command injection**: NEVER use `eval` on user input - use parameter expansion
- [ ] **Input validation**: Validate format of security-sensitive inputs (GPG keys, hostnames)
- [ ] **File permissions**: Explicit chmod (600/700) for sensitive config files
- [ ] **Network security**: HTTPS-only with certificate validation
- [ ] **Path validation**: Prevent directory traversal attacks with realpath checks
- [ ] **Temporary files**: Secure creation with cleanup traps
- [ ] **Variable quoting**: Always quote variables: `"$variable"`
- [ ] **Error messages**: Don't expose sensitive paths or information
- [ ] **Cleanup**: Clear actual secrets (passphrases, keys) - not public data
- [ ] **Dependencies**: Use `command -v` detection, never hardcode paths
- [ ] **Portability**: Generate configs dynamically, avoid hardcoded system paths

## Critical Security Issues in Current Codebase

### ❌ Command Injection (CRITICAL - Fix First)
```bash
# Current dangerous code in dotfiles.sh:
line=$(eval echo "$line")          # Lines 22, 458, 549

# Safe replacement:
target="${target/#\~/$HOME}"
target="${target//\$XDG_CONFIG_DIR/$XDG_CONFIG_DIR}"
```

### ❌ Insecure File Permissions (HIGH)
```bash
# Current issue in dotfiles.sh:
echo "config" > "$config_file"     # No explicit permissions

# Safe replacement:
touch "$config_file"
chmod 600 "$config_file"
echo "config" > "$config_file"
```

### ❌ Missing Cleanup Traps (HIGH) 
```bash
# Current issue in shell/utils.sh:
temp_dir=$(mktemp -d)              # No cleanup on exit

# Safe replacement:
temp_dir=$(mktemp -d)
chmod 700 "$temp_dir"
trap "rm -rf '$temp_dir'" EXIT INT TERM
```

### ❌ Missing Shell Safety Modes (MEDIUM)
```bash
# Current dotfiles.sh header:
#!/bin/bash
set -e

# Enhanced safety (recommended):
#!/usr/bin/env zsh
set -euo pipefail  # exit on error, undefined vars, pipe failures
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
```

## Code Quality Standards

- **Always quote variables**: `"$variable"`
- **Use explicit returns**: `return 0` for success, `return 1` for failure
- **Check dependencies**: Verify tools exist before using
- **Graceful degradation**: Handle missing tools/configs
- **Consistent error messages**: Use same format/colors
- **Performance first**: Avoid expensive operations in shell startup
- **Security first**: Validate input, secure credentials, audit actions

This project prioritizes security, performance, and maintainability in a bash/macOS environment using GNU Stow for configuration management.