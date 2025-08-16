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
- **Architecture**: Distributed documentation in per-directory `agent.md` files

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

## Bash/Shell Development Patterns

### Path Resolution (Critical)

**NEVER hardcode dotfiles directory paths** - this is a common mistake that breaks the system.

```bash
# ❌ NEVER hardcode paths (common Claude mistake)
DOTFILES_DIR="/Users/ian/code/src/github.com/ianlivingstone/dotfiles"
SHELL_DIR="$DOTFILES_DIR/shell"

# ✅ ALWAYS derive paths dynamically with symlink resolution
SCRIPT_PATH="${BASH_SOURCE[0]:-${(%):-%N}}"

# Resolve symlinks to get the real path (critical for stowed files)
if [[ -L "$SCRIPT_PATH" ]]; then
    local target="$(readlink "$SCRIPT_PATH")"
    # Handle relative symlinks by making them absolute
    if [[ "$target" != /* ]]; then
        SCRIPT_PATH="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)/$target"
    else
        SCRIPT_PATH="$target"
    fi
fi

COMPONENT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
DOTFILES_DIR="$(dirname "$COMPONENT_DIR")"
SHELL_DIR="$DOTFILES_DIR/shell"

# ✅ Use utility functions for common operations
get_shell_dir()          # Portable path resolution with symlinks
get_xdg_config_dir()     # Consistent XDG directory handling
```

**Why Dynamic Path Resolution is Required:**
- GNU Stow creates symlinks from `~/` to actual dotfiles directory
- Hardcoded paths break when dotfiles location changes between machines
- Symlink resolution ensures scripts find source files, not symlinked locations
- Multiple users/environments require path portability

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

### Strict Mode with External Tools
```bash  
# ✅ Handling external tools that are incompatible with strict mode
# Problem: Tools like GVM have internal scripts that fail with set -euo pipefail

# ✅ Temporary strict mode disable pattern
handle_external_tool() {
    # Save current strict mode settings
    local saved_errexit="" saved_nounset="" saved_pipefail=""
    [[ $- == *e* ]] && saved_errexit="e"
    [[ $- == *u* ]] && saved_nounset="u" 
    [[ $- == *o* ]] && saved_pipefail="o pipefail"
    
    # Disable strict mode and error trap
    set +euo pipefail
    trap - ERR
    
    # Run external tool
    source "$external_tool_script"
    external_tool_command --options
    
    # Restore strict mode and error trap
    [[ -n "$saved_errexit" ]] && set -e
    [[ -n "$saved_nounset" ]] && set -u
    [[ -n "$saved_pipefail" ]] && set -o pipefail
    trap 'echo "❌ Installation failed at line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR
}

# ❌ Don't try to DRY this up with functions - shell state is context-dependent
# The inline approach is more reliable than function-based state management

# ✅ Debug output suppression (don't set GVM_DEBUG=0, just redirect stderr)
if external_tool --command 2>/dev/null; then
    echo "Success"
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

### Zsh Array Compatibility Issues  
```bash
# ❌ Bash-style array expansion (fails in zsh)
for i in "${!array[@]}"; do          # "bad substitution" error in zsh
    echo "${array[$((i+1))]}"        # 0-based indexing assumption
done

# ✅ Zsh-compatible array iteration
local i=1
for item in "${array[@]}"; do        # Direct iteration, no index expansion
    echo "$i. $item"
    ((i++))
done

# ❌ Bash-style comma splitting (fails in zsh)
IFS=',' read -ra items <<< "$input"  # "bad option: -a" in zsh

# ✅ Zsh-specific array splitting  
local items_array=(${(s:,:)input})   # Zsh parameter expansion flags
for item in "${items_array[@]}"; do
    # Process each item
done

# ❌ Bash array indexing (off-by-one in zsh)
array[0]="first"                     # 0-based in bash
selected_item="${array[$((index-1))]}" # Wrong in zsh

# ✅ Zsh array indexing (1-based by default)  
array[1]="first"                     # 1-based in zsh
selected_item="${array[$index]}"     # Direct index, no subtraction needed

# ✅ Arithmetic expressions in strict mode
# ❌ Problematic:
((count++))                          # Can fail with "operator expected at '0'"

# ✅ Safe alternatives:
count=$((count + 1))                 # Explicit arithmetic
[[ -n "${count:-}" ]] && count=$((count + 1)) # With undefined variable check
```

### Shell Compatibility Rules
- **Never use `readarray`** - not available on all systems
- **Test zsh-specific features** - arrays, parameter expansion, globbing differ
- **Use `[[ ]]` instead of `[ ]`** for conditionals
- **Quote all variables**: `"$var"` not `$var`
- **Use portable shebang**: `#!/usr/bin/env zsh`
- **Understand array indexing**: zsh is 1-based, bash is 0-based

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

### User Input Handling in Strict Mode
```bash
# ❌ Problematic: read -p flag incompatible with strict mode
read -p "Enter name: " name        # "no coprocess" error in strict mode

# ✅ Strict mode compatible user input
get_user_input() {
    local prompt="$1" var_name="$2"
    local user_input=""              # Initialize to avoid "parameter not set"
    
    printf "%s: " "$prompt"         # Use printf instead of -p flag
    read -r user_input              # Read without -p flag
    
    # Safe undefined variable check before use
    if [[ -z "${user_input:-}" ]]; then
        echo "Input cannot be empty" >&2
        return 1
    fi
    
    # Return via global variable or echo (depending on use case)
    eval "$var_name='$user_input'"   # Only safe when var_name is controlled
}

# ✅ Usage example
local git_name=""
if get_user_input "Enter your name" "git_name"; then
    echo "Got name: $git_name"
else
    echo "Failed to get user input" >&2
fi
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

### Security Permission Management
```bash
# ✅ Comprehensive security permission validation and auto-fix
# Unified function with multiple modes:
validate_security_permissions() {
    # Modes: --fix (auto-fix), --quiet (silent), --startup (warn-only)
    # Files protected with 600: config files, GPG files, SSH private keys
    # Directories protected with 700: .gnupg, .ssh, ~/.config subdirs
}

# ✅ Shell startup security check (warn-only, NO auto-fix)
quick_security_check() {
    validate_security_permissions --startup  # Detection only!
}

# ✅ Manual permission fixing (explicit user action)
fix_security_permissions() {
    validate_security_permissions --fix      # User-initiated fix
}

# ✅ Security-first principle: NEVER auto-fix without user consent
# Shell startup should WARN about issues, not fix them silently
```

### Security Permission Patterns
```bash
# ✅ Files that MUST be 600 (user read/write only)
~/.config/git/machine.config     # Git credentials and signing keys
~/.config/ssh/machine.config     # SSH key configuration
~/.gnupg/gpg.conf                # GPG configuration
~/.gnupg/gpg-agent.conf          # GPG agent configuration
~/.ssh/id_*                      # SSH private keys (not .pub files)

# ✅ Directories that MUST be 700 (user access only)
~/.gnupg                         # GPG directory
~/.ssh                           # SSH directory
~/.config/ssh                    # SSH config directory
~/.config/git                    # Git config directory
~/.config/*                      # ALL config subdirectories

# ✅ Secure file creation pattern
touch "$secure_file"
chmod 600 "$secure_file"            # Set before writing sensitive data
echo "sensitive data" > "$secure_file"

# ✅ Secure directory creation pattern
mkdir -p "$secure_dir" && chmod 700 "$secure_dir"
```

### Security Validation on Shell Startup
```bash
# ✅ Warn-only approach (implemented in prompt.sh)
if [[ $- == *i* ]]; then
    quick_security_check             # Detects issues, shows warnings
    # NO automatic fixing - requires user action
fi

# Example warning output:
# ⚠️  SECURITY WARNING: Found 2 permission issue(s) that need attention!
#    Run 'fix_security_permissions' to fix, or 'dotfiles status' for details
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
- [ ] **Version Management**: Use `get_version_requirement()` for centralized version lookup
- [ ] **Version Validation**: All tools validate against `versions.config` requirements
- [ ] **Portability**: Generate configs dynamically, avoid hardcoded system paths

## Version Management Architecture

This project uses centralized version management via `versions.config`:

### Key Components
1. **`versions.config`** - Single source of truth for all tool version requirements
2. **`get_version_requirement()`** - Utility function to read versions from config
3. **`validate_tool_versions()`** - Function to validate all tools against requirements
4. **Shell modules** - Use centralized version lookup instead of individual config files

### Migration from Individual Configs
The previous approach used separate files (`nvm.config`, `gvm.config`) which created:
- **Duplication** - Same version info in multiple places
- **Inconsistency** - Could get out of sync between files
- **Maintenance overhead** - Multiple files to update for version changes

**New consolidated approach:**
```bash
# Old pattern (deprecated)
load_config "$MODULE_DIR/tool.config" "TOOL_VERSION" "fallback-value"

# New pattern (current)
TOOL_VERSION=$(get_version_requirement "tool" || echo "fallback-version")
```

### Version Validation
- **Status integration** - `dotfiles status` shows version compliance for all tools
- **Prefix handling** - Properly compares versions with prefixes (v24.1.0, go1.24.1)
- **Team consistency** - Shared requirements ensure consistent environments
- **Clear reporting** - Shows current vs required versions for non-compliant tools

## Architecture Documentation Guidelines

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
├── shell/agent.md              # Shell configuration architecture
├── nvim/agent.md               # Neovim configuration architecture  
├── git/agent.md                # Git configuration architecture
├── ssh/agent.md                # SSH configuration architecture
├── tmux/agent.md               # Tmux configuration architecture
└── [component]/agent.md        # Component-specific architecture
```

### Documentation Maintenance Rules

#### When Making Changes
- MUST update the component's `agent.md` file when modifying that component
- MUST update integration sections in related component `agent.md` files for cross-component changes
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

## Claude Code Configuration Management

### .claude_code File Guidelines

**MUST include in .claude_code:**
- Safe read-only tools (Read, Grep, Glob, LS, TodoWrite)
- Safe bash commands (ls, pwd, cd, cat, head, tail, which, command)
- Read-only git commands (status, log, diff, show, branch)
- Read-only system commands (version checks, list operations)
- Repository-specific utilities (./dotfiles.sh status, ~/tmux.sh get_battery_status)
- Generic patterns that work across all machines and users

**NEVER include in .claude_code:**
- Destructive commands (rm, mv with overwrite potential, chmod)
- Write operations (git commit, git push, package installs)
- System modification commands (sudo operations, system configs)
- User-specific or machine-specific paths
- Commands that modify state without explicit user consent

**Example safe .claude_code structure:**
```json
{
  "trusted_tools": ["Read", "Grep", "Glob", "LS", "TodoWrite"],
  "trusted_bash_commands": [
    "git status", "git log", "git diff",
    "tmux list-*", "tmux show-*", 
    "./dotfiles.sh status",
    "npm --version", "brew list"
  ],
  "repository_context": {
    "description": "Generic project description",
    "build_commands": ["safe build commands"],
    "test_commands": ["safe test commands"]
  }
}
```

**Maintenance Guidelines:**
- MUST update .claude_code when adding new safe utility scripts
- MUST review trusted commands periodically for security
- SHOULD commit .claude_code to share convenience with other users (if all entries are safe)
- NEVER add commands that could cause data loss or security issues
- MUST test .claude_code changes with fresh Claude sessions

**Security Review Process:**
- MUST verify all trusted commands are truly read-only
- MUST ensure no user-specific paths or credentials are included
- MUST test that malicious arguments cannot cause harm via trusted commands
- SHOULD periodically audit trusted command list for security implications

This project prioritizes security, performance, and maintainability in a bash/macOS environment using GNU Stow for configuration management.