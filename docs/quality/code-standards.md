# Code Quality Standards

## Shell Scripting Standards

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
# ✅ GOOD: Clear return values
function check_something() {
    if [[ condition ]]; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# ❌ BAD: Implicit return (unclear intent)
function check_something() {
    [[ condition ]]
}
```

### Check dependencies
```bash
# ✅ GOOD: Verify tool exists before using
if ! command -v tool &> /dev/null; then
    echo "Error: tool not found"
    echo "Install with: brew install tool"
    return 1
fi
tool --version

# ❌ BAD: Assume tool exists
tool --version  # May fail
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
eval "$(starship init zsh)"  # Fails if not installed
```

### Consistent error messages
```bash
# ✅ GOOD: Consistent format
echo "Error: Git identity not configured"
echo "Run: ./dotfiles.sh install"
return 1

# ❌ BAD: Inconsistent format
echo "ERROR!!! no git config"
echo "try running install"
exit 1  # Use return in functions
```

### Provide actionable guidance
```bash
# ✅ GOOD: Tell user how to fix
if [[ ! -f ~/.config/git/machine.config ]]; then
    echo "Error: Git machine config not found"
    echo "Run: ./dotfiles.sh install"
    echo "Or manually create: ~/.config/git/machine.config"
    return 1
fi

# ❌ BAD: Unhelpful message
if [[ ! -f ~/.config/git/machine.config ]]; then
    echo "Config missing"
    return 1
fi
```

## Security Requirements

### Validate user input
```bash
# ✅ GOOD: Validate before use
read -p "Enter filename: " filename
if [[ ! "$filename" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Error: Invalid filename"
    return 1
fi
# Safe to use now

# ❌ BAD: Direct use of user input (command injection risk)
read -p "Enter filename: " filename
rm "$filename"
```

### Secure network operations
```bash
# ✅ GOOD: Enforce HTTPS with modern TLS
SECURE_CURL="curl --proto '=https' --tlsv1.2"
$SECURE_CURL -sSfL https://example.com/script.sh | bash

# ❌ BAD: Insecure (allows HTTP, old TLS)
curl http://example.com/script.sh | bash
```

### Protect credentials
```bash
# ✅ GOOD: Clear sensitive variables after use
read -s -p "Enter password: " password
# ... use password ...
unset password

# ❌ BAD: Leave credentials in memory
read -p "Enter password: " password
# ... use password ...
# password still accessible
```

## Performance Guidelines

### Avoid expensive operations in shell startup
```bash
# ✅ GOOD: Defer expensive operations
alias update-nvim='nvim --headless "+Lazy! sync" +qa'

# ❌ BAD: Runs on every shell startup (slow)
nvim --headless "+Lazy! sync" +qa
```

### Cache expensive results
```bash
# ✅ GOOD: Cache brew --prefix result
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    HOMEBREW_PREFIX="$(brew --prefix)"
    export HOMEBREW_PREFIX
fi

# ❌ BAD: Call brew --prefix every time (slow)
export PATH="$(brew --prefix)/bin:$PATH"
```

### Guard against multiple sourcing
```bash
# ✅ GOOD: Source guard prevents duplicate loading
[[ -n "$UTILS_LOADED" ]] && return
UTILS_LOADED=1
# ... rest of module ...

# ❌ BAD: No guard (slows startup if sourced multiple times)
# ... module code ...
```

## Code Organization

### Single Responsibility Principle
```bash
# ✅ GOOD: Function does one thing well
validate_ssh_permissions() {
    local ssh_dir="$1"
    [[ -d "$ssh_dir" ]] || return 1
    [[ "$(stat -f %A "$ssh_dir")" == "700" ]]
}

# ❌ BAD: Function does too much
setup_everything() {
    # Creates directories
    # Sets permissions
    # Generates configs
    # Validates everything
    # ... hundreds of lines ...
}
```

### Clear naming
```bash
# ✅ GOOD: Names clearly describe purpose
check_version_compliance() { ... }
install_stow_package() { ... }
validate_key_security() { ... }

# ❌ BAD: Unclear or misleading names
do_stuff() { ... }
handle() { ... }
process() { ... }
```

### Consistent formatting
```bash
# ✅ GOOD: Consistent style
if [[ condition ]]; then
    action
fi

for item in list; do
    action
done

# ❌ BAD: Inconsistent style
if [[ condition ]]
then action
fi

for item in list
do action; done
```

## Documentation Standards

### Function documentation
```bash
# ✅ GOOD: Clear documentation
# Validates SSH key permissions
# Arguments:
#   $1 - Path to SSH directory
# Returns:
#   0 if permissions correct, 1 otherwise
validate_ssh_permissions() {
    local ssh_dir="$1"
    [[ -d "$ssh_dir" ]] || return 1
    [[ "$(stat -f %A "$ssh_dir")" == "700" ]]
}

# ❌ BAD: No documentation
validate_ssh_permissions() {
    local ssh_dir="$1"
    [[ -d "$ssh_dir" ]] || return 1
    [[ "$(stat -f %A "$ssh_dir")" == "700" ]]
}
```

### Inline comments
```bash
# ✅ GOOD: Explain why, not what
# Use cache to avoid expensive brew --prefix call on every startup
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    HOMEBREW_PREFIX="$(brew --prefix)"
fi

# ❌ BAD: Comment restates obvious code
# Check if HOMEBREW_PREFIX is empty
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    # Set HOMEBREW_PREFIX to output of brew --prefix
    HOMEBREW_PREFIX="$(brew --prefix)"
fi
```

## Examples of Good and Bad Patterns

### Variable Quoting
```bash
# ✅ GOOD
path="/path/to/file"
cat "$path"

# ❌ BAD
path="/path/to/file"
cat $path  # Word splitting, glob expansion
```

### Array Usage
```bash
# ✅ GOOD
cmd=(stow --no --restow --target="$target" "$package")
"${cmd[@]}"

# ❌ BAD
cmd="stow --no --restow --target=$target $package"
$cmd  # Word splitting issues
```

### Conditional Execution
```bash
# ✅ GOOD
if command -v tool &> /dev/null; then
    tool --do-thing
else
    echo "Tool not found"
    return 1
fi

# ❌ BAD
command -v tool &> /dev/null && tool --do-thing  # No error handling
```

### Error Handling
```bash
# ✅ GOOD
if ! dangerous_operation; then
    echo "Error: Operation failed"
    cleanup
    return 1
fi

# ❌ BAD
dangerous_operation  # Ignores failure
```

## Code Review Checklist

Before committing code:
- [ ] All variables quoted
- [ ] Explicit return values
- [ ] Dependencies checked before use
- [ ] Error messages are clear and actionable
- [ ] User input validated
- [ ] No credentials in code
- [ ] Network operations use HTTPS
- [ ] No expensive operations in shell startup
- [ ] Functions have single responsibility
- [ ] Names are clear and descriptive
- [ ] Code is documented
- [ ] Shellcheck passes

## Quality Assurance Process

### Pre-commit
1. Run shellcheck on modified scripts
2. Test modified functionality
3. Review changes for security issues
4. Verify code follows standards

### Pre-merge
1. Full test suite passes
2. All shellcheck warnings addressed
3. Security review complete
4. Documentation updated

### Post-merge
1. Monitor for issues
2. Gather feedback
3. Address issues quickly
4. Update standards if needed

## Cross-References

- docs/development/shell-patterns.md (Implementation patterns)
- docs/security/patterns.md (Security patterns)
- docs/development/testing-debugging.md (Testing approaches)
- docs/quality/documentation-standards.md (Documentation)
