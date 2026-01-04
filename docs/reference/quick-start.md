# Quick Start Guide

This guide helps new contributors get oriented quickly.

## For New Contributors

### First Steps (5 minutes)

1. **Read user documentation:**
   ```bash
   # Read README.md in repository root
   cat README.md
   ```

2. **Understand high-level architecture:**
   ```bash
   # Read ARCHITECTURE.md
   cat ARCHITECTURE.md
   ```

3. **Check current status:**
   ```bash
   # See what's installed
   ./dotfiles.sh status
   ```

### Quick Architecture Overview (10 minutes)

**Core Concepts:**
- **GNU Stow:** Manages symlinks from repository to home directory
- **packages.config:** Lists all packages to install
- **Machine configs:** Personal data stored in ~/.config/, not in repo
- **Security-first:** Credentials never committed, permissions validated

**Key Files:**
- `dotfiles.sh` - Main management script
- `packages.config` - Package list
- `versions.config` - Version requirements
- `CLAUDE.md` - AI agent context (you're here for AI assistance)

### Most Common Tasks

**Add a new tool configuration:**
```bash
# 1. Create package directory
mkdir newtool

# 2. Add config files (mirror target structure)
mkdir -p newtool/.config/newtool
echo "config" > newtool/.config/newtool/config.yml

# 3. Add to packages.config
echo "newtool" >> packages.config

# 4. Test
./dotfiles.sh status
./dotfiles.sh reinstall

# 5. Verify
ls -la ~/.config/newtool/
```

**Modify existing package:**
```bash
# 1. Edit files in package directory
vim git/.gitconfig

# 2. Reinstall
./dotfiles.sh reinstall

# 3. Verify
cat ~/.gitconfig  # Should show changes
```

**Update versions:**
```bash
# 1. Edit versions.config
vim versions.config

# 2. Run update
./dotfiles.sh update

# 3. Verify
node --version
go version
```

## For AI Agents

### If You're Reading This as an Agent

**Primary context file:**
- Read CLAUDE.md (200 lines, navigation hub)

**For detailed guidance:**
- Use CLAUDE.md decision tree to find relevant docs/
- Read only docs/ files needed for your task
- Reference component AGENTS.md for implementation details

**Common agent workflows:**
- Adding features → docs/development/adding-features.md
- GNU Stow packages → docs/development/package-management.md
- Shell scripts → docs/development/shell-patterns.md
- Security review → docs/security/patterns.md

**When to use sub-agents:**
- Feature planning → product-manager agent
- Architecture decisions → architecture-assistant agent
- Shell validation → shell-validator agent
- Security audits → security-auditor agent

## Key Files to Read First

### For Understanding System
1. **README.md** - User documentation, features
2. **ARCHITECTURE.md** - Design principles, why things are this way
3. **CLAUDE.md** - AI agent context, where to find information

### For Development
1. **docs/development/adding-features.md** - Feature integration checklist
2. **docs/development/package-management.md** - GNU Stow patterns
3. **docs/security/patterns.md** - Security requirements

### For Specific Components
1. **shell/AGENTS.md** - Shell configuration architecture
2. **git/AGENTS.md** - Git configuration architecture
3. **nvim/AGENTS.md** - Neovim configuration architecture
4. **ssh/AGENTS.md** - SSH configuration architecture

## Development Workflow Overview

### Making Changes

1. **Understand current state:**
   ```bash
   ./dotfiles.sh status
   git status
   ```

2. **Make changes:**
   ```bash
   # Edit files in package directories
   # OR create new packages
   ```

3. **Test changes:**
   ```bash
   ./dotfiles.sh status    # See what would change
   ./dotfiles.sh reinstall # Apply changes
   ```

4. **Validate:**
   ```bash
   # Check symlinks created correctly
   # Test functionality
   # Run ./dotfiles.sh status again
   ```

5. **Commit:**
   ```bash
   git add .
   /commit  # Uses GPG-signed commit
   ```

### Before Committing

**Check list:**
- [ ] `./dotfiles.sh status` passes
- [ ] Changes tested (install/reinstall cycle)
- [ ] No credentials in `git status`
- [ ] Documentation updated
- [ ] Security validated

## Common Pitfalls for New Contributors

### Putting machine-specific data in repo
**Problem:** Committing personal email, SSH keys, etc.
**Solution:** Use ~/.config/ machine.config pattern

### Breaking install/reinstall workflow
**Problem:** Feature works for you, fails on fresh install
**Solution:** Test `./dotfiles.sh install` on clean machine

### Not testing complete cycle
**Problem:** Works after initial install, breaks on reinstall
**Solution:** Test install → uninstall → reinstall cycle

### Forgetting to update documentation
**Problem:** Others don't know what changed or how to use it
**Solution:** Update README.md, component AGENTS.md, docs/ as needed

## Getting Help

**For understanding architecture:**
- Read ARCHITECTURE.md
- Read docs/architecture/overview.md

**For specific tasks:**
- Use CLAUDE.md decision tree
- Read relevant docs/ files
- Check component AGENTS.md files

**For security questions:**
- Read docs/security/overview.md
- Read docs/security/patterns.md
- Use security-auditor agent

**For feature planning:**
- Read docs/development/adding-features.md
- Use product-manager agent

## Next Steps

After quick start:
1. Explore docs/ for detailed guidance
2. Read component AGENTS.md for implementation details
3. Try adding a simple package
4. Review security patterns
5. Understand complete feature lifecycle

## Cross-References

- README.md (User documentation)
- ARCHITECTURE.md (Design principles)
- CLAUDE.md (AI agent context)
- docs/development/adding-features.md (Feature workflow)
