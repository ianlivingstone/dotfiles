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