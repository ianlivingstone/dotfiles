# Shell Configuration Architecture

**📋 Agent Rules Compliance**: This file follows Agent Rules specification using imperative statements with RFC 2119 keywords and flat bullet list format.

## Overview
The shell package provides a modular Zsh configuration system with graceful error handling and performance optimization.

## Design Principles
- MUST handle specific functionality independently in each module
- MUST fail safely without breaking shell startup (graceful degradation)
- MUST use fast filesystem checks instead of expensive command calls
- MUST use shared functions to prevent code duplication
- MUST use centralized requirements from `versions.config`

## Module Structure

```
shell/
├── .zshrc              # Minimal entry point & module loader
├── utils.sh            # Shared utility functions
├── core.sh             # PATH, completion, basic settings
├── aliases.sh          # Command aliases
├── languages.sh        # Programming language environments
├── functions.sh        # Utility functions & status reporting
├── security.sh         # Security validation
├── agents.sh           # SSH and GPG agent management
├── prompt.sh           # Shell prompt configuration
├── nvm.sh              # Node.js version management module
└── gvm.sh              # Go version management module
```

## Module Loading Order
**Critical for dependencies - must be maintained:**

1. **`utils.sh`** - Utility functions (path resolution, version lookup)
2. **`core.sh`** - Basic shell setup (PATH, completion)
3. **`aliases.sh`** - Command shortcuts
4. **`languages.sh`** - Programming environments (NVM, GVM, Rust)
5. **`functions.sh`** - Status reporting and utility functions
6. **`security.sh`** - Key validation and security checks
7. **`agents.sh`** - SSH/GPG agent management
8. **`prompt.sh`** - Shell prompt and status display

## Key Design Features

### Centralized Utilities (`utils.sh`)
Provides shared functions used across all modules:

- **`get_shell_dir()`** - Portable path resolution with symlink support
- **`get_version_requirement()`** - Read versions from centralized config
- **`add_to_path()`** - Safe PATH management with deduplication
- **`show_warning()`** - Consistent warning message format
- **`load_config()`** - Config file loading with fallbacks (legacy)

### Version Manager Modules
Dedicated modules for each language environment:

- **Fast filesystem checks** instead of slow manager commands
- **Centralized configuration** in `versions.config`
- **Unified update system** via `dotfiles update`
- **Proper PATH management** ensuring binaries are available

### Performance Optimizations
- **No expensive operations** during shell startup
- **Warnings-only approach** for missing versions
- **Filesystem-based checks** for version detection
- **Lazy loading** where possible

## Development Guidelines

### Creating New Modules
MUST follow this template pattern:

```bash
#!/usr/bin/env zsh
# Tool Name setup and configuration
# SOURCED MODULE: Uses graceful error handling, never use set -e

# Get module directory
MODULE_DIR="$(get_shell_dir)"

# Get version requirement from versions.config
TOOL_VERSION=$(get_version_requirement "tool" || echo "default-version")

# Check if tool manager exists
if [[ -s "$HOME/.tool/scripts/tool" ]]; then
    source "$HOME/.tool/scripts/tool"
    
    # Fast filesystem checks
    if [[ ! -d "$HOME/.tool/versions/$TOOL_VERSION" ]]; then
        show_warning "Tool $TOOL_VERSION not installed"
    fi
    
    # Use configured version and manage PATH
    if [[ -d "$HOME/.tool/versions/$TOOL_VERSION" ]]; then
        tool use "$TOOL_VERSION" > /dev/null 2>&1 || true
        add_to_path "$HOME/.tool/versions/$TOOL_VERSION/bin"
    fi
else
    echo "❌ Tool not found. Install with: [installation command]"
fi
```

### Essential Patterns

**Path Resolution:**
- MUST use the utility function: `MODULE_DIR="$(get_shell_dir)"`
- NEVER hardcode paths: `MODULE_DIR="/Users/user/dotfiles/shell"`

**Version Requirements:**
- MUST use centralized version management: `TOOL_VERSION=$(get_version_requirement "tool" || echo "default-version")`
- NEVER use separate config files (deprecated pattern)

**PATH Management:**
- MUST use safe PATH addition: `add_to_path "/path/to/tool/bin"`
- NEVER manually manage PATH: `export PATH="/path/to/tool/bin:$PATH"` (causes duplicates)

**Warning Messages:**
- MUST use consistent warning format: `show_warning "Tool $VERSION not installed"`
- NEVER hardcode warning messages with inconsistent format

## Error Handling Strategy

### Sourced Modules vs Installation Scripts
- **Sourced modules** (shell/*.sh): Use graceful error handling, never `set -e`
- **Installation scripts** (dotfiles.sh): Use strict mode `set -euo pipefail`

### Module Dependencies
- All modules use `get_shell_dir()` for portable path resolution
- Language modules use shared utility functions from `utils.sh`
- Functions module displays status using same utility patterns

## Performance Considerations

### Startup Optimization
- Modules should complete loading in <50ms total
- Avoid expensive command calls during sourcing
- Use filesystem checks instead of version manager commands
- Defer heavy operations to explicit user commands

### Memory Usage
- Minimize global variable pollution
- Use local variables in functions
- Clean up temporary variables after use

## Security Requirements

### Shell Safety
- **Never use `set -e` in sourced modules** - can exit user's shell
- **Always quote variables** to prevent word splitting
- **Validate input** before using in commands
- **Use safe parameter expansion** instead of `eval`

### Version Management Security
- Validate versions from `versions.config` before use
- Never execute arbitrary version strings as commands
- Use safe defaults when version lookup fails

## Integration Points

### With Main Dotfiles System
- Shell modules read from centralized `versions.config`
- Status reporting integrates with `./dotfiles.sh status`
- Update commands work with `./dotfiles.sh update`

### With Other Packages
- Git configuration uses shell environment variables
- SSH agent integration through `agents.sh`
- Security validation coordinates with file permissions

## Testing and Validation

### Manual Testing
```bash
# Test individual modules
source shell/module.sh

# Test module loading order
source shell/.zshrc

# Validate path resolution
echo $SHELL_DIR

# Check version requirements
get_version_requirement "node"
```

### Performance Testing
```bash
# Time shell startup
time zsh -c 'exit'

# Profile module loading
ZSH_PROF=1 zsh -c 'exit'
```

This architecture ensures the shell configuration is maintainable, performant, and secure while providing a consistent development experience across all machines.

## Shell Development Patterns

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

## Zsh Compatibility Issues  
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