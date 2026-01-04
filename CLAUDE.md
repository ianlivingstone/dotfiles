# Dotfiles Project Context for Claude

This is a bash/shell-based dotfiles management system for macOS using GNU Stow.

## Quick Reference

- **Language**: Bash/Zsh shell scripts
- **Platform**: macOS (Darwin)
- **Package Manager**: GNU Stow for symlink management
- **Security**: GPG signing required, SSH key validation
- **Architecture**: Distributed docs in docs/ and component AGENTS.md files

## Repository Navigation

**Core files:**
- `dotfiles.sh` - Main management script (install, status, update, reinstall)
- `packages.config` - Package list with target locations
- `versions.config` - Version requirements for all tools

**Documentation:**
- `README.md` - User documentation and features
- `ARCHITECTURE.md` - High-level design principles
- **`docs/`** - Detailed development guides (READ THIS FOR DETAILS)
- `[component]/AGENTS.md` - Component-specific implementation

**For detailed information:**
- Read ARCHITECTURE.md FIRST for design principles
- Read docs/ files for specific topics (see decision tree below)
- Read component AGENTS.md for implementation details

## Finding Information - Decision Tree

### Adding New Features
**→ Read:** `docs/development/adding-features.md` (CRITICAL - has feature integration checklist)
**→ Use:** product-manager agent for planning
**→ Use:** architecture-assistant agent for design

### GNU Stow Packages
**→ Read:** `docs/development/package-management.md`
**→ Use:** architecture-assistant agent

### Shell Scripts
**→ Read:** `docs/development/shell-patterns.md`
**→ Read:** `shell/AGENTS.md`
**→ Use:** shell-validator agent

### Security
**→ Read:** `docs/security/patterns.md`
**→ Read:** `docs/security/multi-machine.md`
**→ Use:** security-auditor agent

### Testing/Debugging
**→ Read:** `docs/development/testing-debugging.md`

### dotfiles.sh Commands
**→ Read:** `docs/reference/dotfiles-commands.md`

### Version Management
**→ Read:** `docs/development/version-management.md`
**→ Read:** `shell/AGENTS.md`

### macOS Patterns
**→ Read:** `docs/development/macos-patterns.md`

### Claude Code Integration
**→ Read:** `docs/development/claude-code-integration.md`

### Architecture & Design
**→ Read:** `docs/architecture/overview.md`
**→ Read:** `ARCHITECTURE.md`

### Security Auditing
**→ Read:** `docs/security/auditing.md`
**→ Use:** security-auditor agent

## Essential Rules (NEVER violate these)

### Security
- **NEVER** commit credentials, API keys, or personal data
- **NEVER** run `git add` in any form (user stages changes)
- **ALWAYS** use machine.config in ~/.config/ for personal data
- **ALWAYS** validate file permissions (600 for keys, 700 for sensitive dirs)
- **ALWAYS** use secure curl: `curl --proto '=https' --tlsv1.2`
- **ALWAYS** quote variables in shell scripts: `"$variable"`

### Architecture
- **MUST** use GNU Stow for package management
- **MUST** separate machine-specific from shared configs
- **MUST** use native tool includes for layering (Git [include], SSH Include)
- **MUST** update install/reinstall/update workflows when adding features

### Documentation
- **MUST** update docs/ when changing patterns
- **MUST** update component AGENTS.md for component changes
- **MUST** follow Agent Rules specification (RFC 2119, imperative statements)
- **MUST** verify links work after changes

### Development
- **ALWAYS** quote variables: `"$variable"`
- **ALWAYS** validate user input before use
- **ALWAYS** check dependencies exist: `command -v tool`
- **ALWAYS** test install → reinstall → update cycle
- **NEVER** use eval with user input
- **NEVER** hardcode credentials or personal data

## Key Commands

```bash
./dotfiles.sh status          # Check installation & version compliance
./dotfiles.sh install         # Initial installation (prompts for identity)
./dotfiles.sh reinstall       # Safe way to test package changes
./dotfiles.sh update          # Update Node.js, Go to versions.config
./dotfiles.sh uninstall       # Remove all symlinks
```

## Machine-Specific Configuration Pattern

**MUST store personal data in XDG directories, NEVER in repository:**
- Git identity: `~/.config/git/machine.config`
- SSH keys: `~/.config/ssh/machine.config`
- GPG keys: Referenced in git machine.config

**MUST use native tool includes:**
- Git: `[include] path = ~/.config/git/machine.config`
- SSH: `Include ~/.config/ssh/machine.config`

**MUST ensure in .gitignore:**
- `.config/git/machine.config`
- `.config/ssh/machine.config`
- `~/.ssh/id_*`
- `~/.gnupg/`

## Sub-Agent Coordination

Repository includes four specialized agents (see `.claude/agents/README.md`):

**product-manager**: Feature planning, UX oversight, workflow integration
- Use when: Adding features, planning changes, reviewing UX
- Reads: docs/development/adding-features.md

**architecture-assistant**: Code architecture decisions
- Use when: Designing packages, organizing code, structural changes
- Reads: docs/architecture/overview.md, docs/development/package-management.md

**shell-validator**: Bash/zsh validation
- Use when: Writing/reviewing shell scripts
- Reads: docs/development/shell-patterns.md, docs/security/patterns.md

**security-auditor**: Security scanning
- Use when: Security reviews, auditing code
- Reads: docs/security/patterns.md, docs/security/auditing.md

## Documentation Architecture

**CLAUDE.md (this file, 200 lines):**
- Quick reference and navigation
- Essential rules
- Decision tree for finding information

**docs/ (detailed, task-oriented):**
- Comprehensive development patterns (100-200 lines per file)
- Security guidelines with examples
- Architecture deep-dives
- Testing strategies

**ARCHITECTURE.md:**
- High-level design principles
- Why architectural choices were made
- Component relationships

**Component AGENTS.md:**
- Component-specific implementation
- Integration points
- Technical details

For more on documentation strategy: `docs/architecture/documentation-strategy.md`

## Quick Start for Common Tasks

**Commit changes:**
1. Stage changes: `git add <files>` (USER does this, not Claude)
2. Verify: `git status`
3. Commit with single command (5s timeout):
```bash
git commit -S -m "$(cat <<'EOF'
<verb> <what changed>

<why - optional>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**Commit rules:**
- Use imperative mood: "Add feature" not "Added feature"
- Subject: 50-72 chars max
- Be specific: "Add gopls config" not "Update files"
- Full guide: `claude-code/commands/commit.md`

**Add new package:**
1. Create package directory: `mkdir mypackage`
2. Mirror target structure: `mypackage/.config/mypackage/config.yml`
3. Add to packages.config: `echo "mypackage" >> packages.config`
4. Test: `./dotfiles.sh status && ./dotfiles.sh reinstall`

**Modify existing package:**
1. Edit files in package directory
2. Reinstall: `./dotfiles.sh reinstall`
3. Verify changes applied

**Test changes:**
```bash
./dotfiles.sh status        # See what would change
./dotfiles.sh reinstall     # Apply changes
./dotfiles.sh status        # Verify properly stowed
```

## Cross-References

- **README.md** - User documentation
- **ARCHITECTURE.md** - Design principles
- **docs/README.md** - How to use docs/
- **docs/development/adding-features.md** - Feature integration (START HERE for new features)
- **docs/reference/quick-start.md** - Quick start guide
- **.claude/agents/README.md** - Sub-agent documentation

This project prioritizes security, performance, and maintainability in a bash/macOS environment using GNU Stow for configuration management.
