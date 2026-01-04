# Testing and Debugging Patterns

## Manual Testing

### Test individual modules
```bash
# Test shell module in isolation
source shell/security.sh && validate_key_security

# Test with specific configuration
DOTFILES_DEBUG=1 source shell/module.sh
```

### Test package status
```bash
# Check all packages
./dotfiles.sh status

# Check specific package (dry run)
stow --no --restow --verbose=2 --target="$HOME" --dir="$PWD" git
```

### Fresh installation test
```bash
# Test auto-bootstrap (Neovim example)
rm -rf ~/.local/share/nvim && nvim

# Test plugin installation
nvim +Lazy +qa
```

## Validation Checks

### Always validate before proceeding
```bash
# ✅ GOOD: Validate first
if ! validate_key_security; then
    echo "Security validation failed"
    return 1
fi

# ❌ BAD: Assume validation passes
validate_key_security
# Continue without checking
```

### Validate prerequisites
```bash
# Check dependencies exist
check_dependencies() {
    local missing=()
    for tool in git stow nvim tmux; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing dependencies: ${missing[*]}"
        return 1
    fi
    return 0
}
```

## Testing Install/Reinstall/Update Cycle

### Test complete lifecycle
```bash
# 1. Clean install
./dotfiles.sh install

# 2. Verify status
./dotfiles.sh status  # Should show all properly stowed

# 3. Test reinstall
./dotfiles.sh reinstall

# 4. Verify still working
./dotfiles.sh status  # Should show all properly stowed

# 5. Test update
./dotfiles.sh update

# 6. Verify versions updated
node --version  # Should match versions.config
go version      # Should match versions.config

# 7. Test uninstall
./dotfiles.sh uninstall

# 8. Verify cleanup
ls -la ~/ | grep -E '\->'  # Should show no stowed symlinks
```

### Test on clean machine
```bash
# Use Docker for clean environment testing
docker run -it --rm -v "$PWD:/dotfiles" ubuntu:latest bash
cd /dotfiles
./dotfiles.sh install
```

## Debugging Shell Startup Issues

### Enable debug mode
```bash
# Shell module debugging
set -x                   # Enable debug output
source shell/module.sh   # Test module loading
set +x                   # Disable debug output
```

### Check module loading order
```bash
# Verify modules loaded in correct order
echo "Loading path-resolution..."
source shell/path-resolution.sh
echo "Loading utils..."
source shell/utils.sh
echo "Loading security..."
source shell/security.sh
```

### Environment debugging
```bash
# Check environment variables
env | grep DOTFILES     # Check cache variables
echo $PATH | tr ':' '\n'  # Check PATH entries
echo $SHELL_DIR         # Check path resolution
```

## Debugging Stow Issues

### Stow dry run with verbose output
```bash
# See exactly what Stow would do
stow --no --restow --verbose=2 --target="$HOME" --dir="$PWD" git

# Check for conflicts
stow --no --restow --verbose=2 --target="$HOME" --dir="$PWD" git 2>&1 | grep -i conflict
```

### Verify package structure
```bash
# Package structure should mirror target
tree git/
# Should show:
# git/
# └── .gitconfig

# Target should have symlink
ls -la ~/.gitconfig
# Should show: .gitconfig -> /path/to/dotfiles/git/.gitconfig
```

### Debugging Stow conflicts
```bash
# Find existing files that conflict
find ~/ -maxdepth 1 -name ".gitconfig" -type f

# Resolution:
# 1. Back up: mv ~/.gitconfig ~/.gitconfig.backup
# 2. Then: ./dotfiles.sh reinstall
```

## Security Testing

### Test credential isolation
```bash
# Verify no credentials in repository
git status  # Should not show machine.config files
git log --all --full-history -- '*.config' | grep machine

# Check .gitignore coverage
git check-ignore ~/.config/git/machine.config  # Should match
```

### Test permission validation
```bash
# Test SSH key permissions
ls -la ~/.ssh/  # Keys should be 600, directory should be 700

# Test GPG permissions
ls -la ~/.gnupg/  # Should be 700

# Test validation function
source shell/security.sh
validate_key_security  # Should pass or warn
```

### Test input validation
```bash
# Test with malicious input
echo "'; rm -rf /'" | ./dotfiles.sh install  # Should reject

# Test with invalid filenames
./dotfiles.sh status "../../../etc/passwd"  # Should validate
```

## Performance Testing

### Measure shell startup time
```bash
# Test shell startup performance
time zsh -i -c exit

# Test individual module load time
time source shell/module.sh
```

### Identify slow operations
```bash
# Profile shell startup
zsh -x -i -c exit 2>&1 | head -100

# Look for:
# - Expensive command substitutions
# - Multiple external command calls
# - Unguarded expensive operations
```

## Version Compliance Testing

### Test version validation
```bash
# Check version compliance
./dotfiles.sh status  # Should show version compliance

# Test with modified versions.config
# 1. Edit versions.config to require higher version
# 2. Run ./dotfiles.sh status
# 3. Should show version mismatch
# 4. Revert versions.config
```

### Test update command
```bash
# Verify update works
./dotfiles.sh update

# Verify versions match
node --version  # Should match versions.config
go version      # Should match versions.config
```

## Claude Hooks Testing

### Test hook build status
```bash
# Check hooks built
./dotfiles.sh status  # Should show hooks status

# Rebuild hooks
./claude_hooks/build-hooks.sh

# Verify hooks work
# Edit a file, whitespace should be cleaned
```

## Common Testing Scenarios

### Adding a new package
```bash
# 1. Create package structure
mkdir -p testpackage/.config/testpackage
echo "test config" > testpackage/.config/testpackage/config.yml

# 2. Add to packages.config
echo "testpackage" >> packages.config

# 3. Test status
./dotfiles.sh status  # Should show testpackage changes

# 4. Test install
./dotfiles.sh reinstall

# 5. Verify
ls -la ~/.config/testpackage/  # Should be symlink
cat ~/.config/testpackage/config.yml  # Should show "test config"

# 6. Test removal
sed -i '' '/^testpackage$/d' packages.config
./dotfiles.sh reinstall

# 7. Verify cleanup
ls -la ~/.config/testpackage/  # Should not exist
```

### Modifying existing package
```bash
# 1. Modify package file
echo "# New comment" >> git/.gitconfig

# 2. Test status
./dotfiles.sh status  # Should show changes needed

# 3. Reinstall
./dotfiles.sh reinstall

# 4. Verify
grep "# New comment" ~/.gitconfig  # Should be present
```

## Debugging Checklist

When something isn't working:
- [ ] Run `./dotfiles.sh status` to see current state
- [ ] Check for Stow conflicts: `stow --no --restow --verbose=2`
- [ ] Verify package structure mirrors target
- [ ] Check file permissions (600/700 for sensitive files)
- [ ] Verify dependencies installed: `command -v tool`
- [ ] Check shell module loading order
- [ ] Review error messages for clues
- [ ] Test in clean environment (Docker)
- [ ] Verify .gitignore covers sensitive files

## Cross-References

- docs/development/adding-features.md (Testing requirements)
- docs/reference/dotfiles-commands.md (Commands for testing)
- docs/security/patterns.md (Security testing)
- docs/development/shell-patterns.md (Shell debugging)
