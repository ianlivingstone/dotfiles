# Shell Development Patterns

## Bash/Zsh Best Practices

### Always quote variables
```bash
# ✅ GOOD: Properly quoted
file_path="/path/to/file"
cat "$file_path"

# ❌ BAD: Unquoted (word splitting, glob expansion)
cat $file_path
```

### Use explicit returns
```bash
# ✅ GOOD: Explicit return values
check_something() {
    if [[ condition ]]; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# ❌ BAD: Implicit return
check_something() {
    [[ condition ]]  # Return value unclear
}
```

### Check dependencies before using
```bash
# ✅ GOOD: Verify tool exists
if ! command -v tool &> /dev/null; then
    echo "Install with: brew install tool"
    return 1
fi

# ❌ BAD: Assume tool exists
tool --version
```

## Error Handling Patterns

### Graceful degradation
```bash
# ✅ GOOD: Handle missing tools gracefully
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
else
    # Fallback to basic prompt
    PS1='%n@%m:%~$ '
fi

# ❌ BAD: Crash if tool missing
eval "$(starship init zsh)"
```

### Consistent error messages
```bash
# ✅ GOOD: Consistent format
echo "Error: Git identity not configured"
echo "Run: ./dotfiles.sh install"

# ❌ BAD: Inconsistent format
echo "ERROR!!! no git config"
echo "try running install"
```

## Variable Validation

### Validate user input
```bash
# ✅ GOOD: Validate input before use
read -p "Enter filename: " filename
if [[ ! "$filename" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Error: Invalid filename"
    return 1
fi

# ❌ BAD: Direct use of user input
read -p "Enter filename: " filename
rm "$filename"  # Command injection risk!
```

### Use arrays for complex commands
```bash
# ✅ GOOD: Array prevents word splitting
cmd=(stow --no --restow --target="$target" "$package")
"${cmd[@]}"

# ❌ BAD: String concatenation
cmd="stow --no --restow --target=$target $package"
$cmd
```

## Path Resolution Patterns

### Use consistent path variables
```bash
# ✅ GOOD: Defined once, used everywhere
SHELL_DIR="${DOTFILES_SHELL_DIR:-$HOME/.config/shell}"

# ❌ BAD: Hardcoded paths everywhere
source ~/.config/shell/utils.sh
source ~/.config/shell/security.sh
```

### Resolve paths early
```bash
# ✅ GOOD: Resolve at startup
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ❌ BAD: Resolve every time
cd "$(dirname "${BASH_SOURCE[0]}")"
```

## Function Design Patterns

### Single responsibility
```bash
# ✅ GOOD: Function does one thing
validate_ssh_permissions() {
    local ssh_dir="$1"
    [[ -d "$ssh_dir" ]] || return 1
    [[ "$(stat -f %A "$ssh_dir")" == "700" ]]
}

# ❌ BAD: Function does too much
setup_ssh() {
    # Creates directories
    # Sets permissions
    # Generates configs
    # Validates everything
    # ...hundreds of lines...
}
```

### Clear naming
```bash
# ✅ GOOD: Clear what it does
check_version_compliance() { ... }
install_stow_package() { ... }

# ❌ BAD: Unclear names
do_stuff() { ... }
handle() { ... }
```

## Module Structure and Loading

### Source modules in order
```bash
# ✅ GOOD: Dependencies sourced first
source "$SHELL_DIR/path-resolution.sh"
source "$SHELL_DIR/utils.sh"  # Uses path-resolution
source "$SHELL_DIR/security.sh"  # Uses utils

# ❌ BAD: Random order, may fail
source "$SHELL_DIR/security.sh"
source "$SHELL_DIR/path-resolution.sh"
```

### Guard against multiple sourcing
```bash
# ✅ GOOD: Source guard
[[ -n "$UTILS_LOADED" ]] && return
UTILS_LOADED=1

# ❌ BAD: No guard (slows startup)
# Gets sourced multiple times
```

## Performance Optimization

### Avoid expensive operations in shell startup
```bash
# ✅ GOOD: Defer expensive operations
alias update-nvim='nvim --headless "+Lazy! sync" +qa'

# ❌ BAD: Runs on every shell startup
nvim --headless "+Lazy! sync" +qa
```

### Cache expensive results
```bash
# ✅ GOOD: Cache result
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    HOMEBREW_PREFIX="$(brew --prefix)"
    export HOMEBREW_PREFIX
fi

# ❌ BAD: Call every time
export PATH="$(brew --prefix)/bin:$PATH"
```

## macOS-Specific Patterns

### Homebrew integration
```bash
# ✅ GOOD: Check for Homebrew
if command -v brew &> /dev/null; then
    HOMEBREW_PREFIX="$(brew --prefix)"
fi

# ❌ BAD: Assume Homebrew exists
HOMEBREW_PREFIX="$(brew --prefix)"
```

### XDG directory handling
```bash
# ✅ GOOD: Respect existing XDG vars
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# ❌ BAD: Override user's settings
XDG_CONFIG_HOME="$HOME/.config"
```

### File permissions on macOS
```bash
# ✅ GOOD: macOS stat syntax
perm=$(stat -f %A "$file")

# ❌ BAD: Linux stat syntax (fails on macOS)
perm=$(stat -c %a "$file")
```

## Common Pitfalls and Solutions

### Pitfall: Word splitting
```bash
# Problem:
files="file1.txt file2.txt"
cat $files  # Splits into two arguments

# Solution:
cat "$files"  # Treated as single argument
```

### Pitfall: Glob expansion
```bash
# Problem:
pattern="*.txt"
rm $pattern  # Expands glob

# Solution:
rm "$pattern"  # Treated as literal
```

### Pitfall: Command substitution in quotes
```bash
# Problem:
path="$(pwd)/file"  # Works
path="$(pwd) /file"  # Breaks with space

# Solution:
path="$(pwd)/file"  # Keep expressions simple
```

### Pitfall: Exit on error
```bash
# Problem:
set -e
command_that_might_fail  # Script exits

# Solution:
if ! command_that_might_fail; then
    echo "Command failed, continuing..."
fi
```

## Testing Shell Scripts

### Manual testing
```bash
# Test individual modules
source shell/security.sh && validate_key_security

# Test with set -x
set -x
source shell/module.sh
set +x
```

### Validation checks
```bash
# Always validate before proceeding
if ! validate_key_security; then
    echo "Security validation failed"
    return 1
fi
```

## Code Quality Standards

- **Always quote variables**: `"$variable"`
- **Use explicit returns**: `return 0` for success, `return 1` for failure
- **Check dependencies**: Verify tools exist before using
- **Graceful degradation**: Handle missing tools/configs
- **Consistent error messages**: Use same format/colors
- **Performance first**: Avoid expensive operations in shell startup
- **Security first**: Validate input, secure credentials, audit actions

## Cross-References

- docs/security/patterns.md (Security patterns)
- docs/development/testing-debugging.md (Testing approaches)
- shell/AGENTS.md (Shell architecture)
- docs/quality/code-standards.md (Quality standards)
