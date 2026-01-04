# Adding Features to Dotfiles

When adding new functionality to this dotfiles repository, you MUST ensure the feature integrates properly with the install/reinstall/update/security workflows.

## Feature Integration Checklist

### 1. Installation Support (MUST address)
- [ ] Does feature require new dependencies?
  - Add to `dotfiles.sh install` dependency check
  - Document in README.md
  - Add version requirement to versions.config if needed
- [ ] Does feature need initial setup?
  - Add setup steps to `dotfiles.sh install`
  - Prompt user for machine-specific configuration if needed
  - Generate machine.config if needed

**Examples:**
- Adding Git config requires git installed, prompts for user.name/email
- Adding Neovim config requires nvim installed, auto-bootstraps plugins
- Adding SSH config requires ssh client, prompts for key selection

### 2. Reinstall Support (MUST address)
- [ ] Can feature be cleanly removed and reinstalled?
  - Test: Remove symlinks, reinstall, verify works
- [ ] Does feature use GNU Stow properly?
  - Package directory structure mirrors target
  - Added to packages.config
  - Symlinks created correctly
- [ ] Does feature conflict with existing files?
  - Check for conflicts before stowing
  - Back up existing files if needed

**Examples:**
- Adding shell module goes in shell/ package, stowed to ~/
- Adding tool config creates new package, add to packages.config
- Removing feature removes from packages.config, run reinstall

### 3. Update Support (MUST address)
- [ ] Does feature have updateable components?
  - Add to `dotfiles.sh update` if tool has versions
  - Document update process in component AGENTS.md
- [ ] Can users update without breaking setup?
  - Test upgrade path from previous version
  - Preserve user customizations
  - Migrate configs if format changes

**Examples:**
- Language version managers add to update command
- Plugin managers document how to update plugins
- Config format changes provide migration script

### 4. Security Considerations (MUST address)
- [ ] Does feature handle credentials?
  - Machine-specific data in ~/.config/, not repo
  - Update .gitignore for sensitive files
  - Validate file permissions (600/700)
- [ ] Does feature introduce vulnerabilities?
  - No command injection in scripts
  - Validate user input
  - Use secure network patterns
- [ ] Does feature affect GPG signing?
  - Verify commits still signed
  - Check key permissions

**Examples:**
- Git config user email in machine.config
- SSH config keys in ~/.config/ssh/machine.config
- New shell script validate and quote variables

### 5. Documentation (MUST address)
- [ ] User-facing changes documented?
  - Update README.md
  - Include usage examples
  - Document troubleshooting
- [ ] Developer documentation updated?
  - Update or create component AGENTS.md
  - Update ARCHITECTURE.md if architectural change
  - Update relevant docs/ files
- [ ] AI agent context updated?
  - Update CLAUDE.md if pattern changes
  - Update agent instructions if needed

**Examples:**
- New package creates package/AGENTS.md
- New workflow updates docs/development/
- Architecture change updates ARCHITECTURE.md, docs/architecture/

### 6. Testing (MUST complete)
- [ ] Installation tested?
  - `./dotfiles.sh status` passes
  - Feature installs on clean machine
- [ ] Complete cycle tested?
  - Install uninstall reinstall works
  - Update doesn't break feature
- [ ] Security validated?
  - No credentials in git status
  - File permissions correct
  - .gitignore covers sensitive files

**Examples:**
- Package testing status, reinstall, verify symlinks
- Security testing git status, ls -la ~/.config/
- Update testing modify versions.config, run update

## Example: Adding Alacritty Terminal

### 1. Installation Support
```bash
# dotfiles.sh install
if ! command -v alacritty &> /dev/null; then
    echo "Warning: Alacritty not found"
    echo "Install: brew install alacritty"
fi
```

README.md:
```markdown
## Optional: Alacritty Terminal
- Requires: alacritty
- Install: `brew install alacritty`
- Config: ~/.config/alacritty/alacritty.yml
```

### 2. Reinstall Support
```bash
# Create package structure
mkdir -p alacritty/.config/alacritty
cat > alacritty/.config/alacritty/alacritty.yml <<EOF
# Alacritty configuration
...
EOF

# Add to packages.config
echo "alacritty" >> packages.config

# Test
./dotfiles.sh reinstall
```

### 3. Update Support
No version management needed (terminal emulator).

Document in alacritty/AGENTS.md:
```markdown
## Updates
Alacritty updates via homebrew:
`brew upgrade alacritty`

Configuration updates via git:
`cd ~/dotfiles && git pull`
```

### 4. Security
No credentials. Config is fully shareable.

### 5. Documentation
- Update README.md with alacritty section
- Create alacritty/AGENTS.md
- Update ARCHITECTURE.md (add to component list)

### 6. Testing
```bash
./dotfiles.sh status        # Should show alacritty properly stowed
./dotfiles.sh uninstall     # Remove symlinks
./dotfiles.sh reinstall     # Restore symlinks
ls -la ~/.config/alacritty/ # Verify symlink created
```

## Common Pitfalls

### Forgetting install/reinstall integration
**Problem**: Feature works on developer's machine, fails on fresh install.
**Solution**: Always test `./dotfiles.sh install` on clean machine.

### Putting machine-specific data in repo
**Problem**: Personal email/keys committed to git.
**Solution**: Use ~/.config/ machine.config pattern.

### Not testing the complete cycle
**Problem**: Feature breaks on reinstall or update.
**Solution**: Test install uninstall reinstall update cycle.

### Skipping documentation
**Problem**: Others don't know feature exists or how to use it.
**Solution**: Update README.md, create/update AGENTS.md.

## When to Use Sub-Agents

### product-manager Agent
Use for feature planning and UX review:
```
"I want to add Alacritty, help me plan the integration"
```

### architecture-assistant Agent
Use for code architecture decisions:
```
"How should I structure the Alacritty package for GNU Stow?"
```

### shell-validator Agent
Use for shell script validation:
```
"Validate this installation script for Alacritty"
```

### security-auditor Agent
Use for security review:
```
"Audit this feature for security issues"
```

## Self-Check Before Committing

- [ ] Feature integrates with install workflow
- [ ] Feature integrates with reinstall workflow
- [ ] Feature integrates with update workflow (if applicable)
- [ ] Security validated (no credentials, proper permissions)
- [ ] Documentation updated (README, AGENTS.md, docs/)
- [ ] Testing completed (status, full cycle)
- [ ] Product manager would approve this UX
- [ ] Architecture assistant would approve this structure

If all checked, feature is ready to commit!

## Cross-References

- docs/development/package-management.md (GNU Stow details)
- docs/security/patterns.md (Security requirements)
- docs/development/testing-debugging.md (Testing approaches)
