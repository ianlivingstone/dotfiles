# Documentation Architecture Specification

**Created**: 2026-01-03
**Status**: Draft - Awaiting Approval
**Part of**: Claude Code Improvement Plan (Recommendation 1.1)
**Author**: harness-architect agent

## Executive Summary

This specification defines a comprehensive `docs/` directory structure to replace the current 1,433-line CLAUDE.md with a focused, scannable, task-oriented documentation system. The goal is a **60-70% reduction in context consumption** while improving discoverability and maintainability.

**Key Changes**:
- CLAUDE.md shrinks from 1,433 lines to ~200 lines (86% reduction)
- New `docs/` structure with 15 focused files (100-200 lines each)
- Clear navigation strategy for AI agents and humans
- Task-oriented organization for rapid information access
- **Special focus on feature integration workflow** (install/reinstall/update/security)

## Current State Analysis

### CLAUDE.md Content Breakdown (1,433 lines)

| Section | Lines | Target Location |
|---------|-------|-----------------|
| Project overview & navigation | 122 | CLAUDE.md (condensed) |
| GNU Stow package management | 228 | docs/development/package-management.md |
| macOS-specific patterns | 32 | docs/development/macos-patterns.md |
| Multi-machine configuration | 280 | docs/security/multi-machine.md |
| Testing patterns | 18 | docs/development/testing-debugging.md |
| Security guidelines | 244 | docs/security/patterns.md |
| Version management | 3 | docs/development/version-management.md |
| Documentation architecture | 48 | docs/architecture/documentation-strategy.md |
| dotfiles.sh command reference | 303 | docs/reference/dotfiles-commands.md |
| Code quality standards | 9 | docs/quality/code-standards.md |
| Claude Code config | 68 | docs/development/claude-code-integration.md |
| Claude Code hooks | 11 | docs/development/claude-code-integration.md |

**Total**: 1,366 lines can be extracted to focused docs/ files

## Complete docs/ Directory Structure

```
docs/
├── README.md                                    # 100 lines - How to use docs/ (agents & humans)
│
├── architecture/                                # High-level system design
│   ├── overview.md                              # 150 lines - System architecture summary
│   ├── documentation-strategy.md                # 100 lines - This file's implementation
│   └── agent-integration.md                     # 150 lines - How agents use this system
│
├── development/                                 # Development guides
│   ├── adding-features.md                       # 200 lines - ⭐ CRITICAL: Feature integration checklist
│   ├── package-management.md                    # 250 lines - GNU Stow patterns & examples
│   ├── shell-patterns.md                        # 200 lines - Bash/zsh development
│   ├── version-management.md                    # 150 lines - versions.config system
│   ├── testing-debugging.md                     # 150 lines - Testing & debugging patterns
│   ├── macos-patterns.md                        # 100 lines - macOS-specific guidance
│   └── claude-code-integration.md               # 150 lines - Claude Code config & hooks
│
├── security/                                    # Security patterns & guidelines
│   ├── overview.md                              # 150 lines - Security principles
│   ├── patterns.md                              # 200 lines - Security implementation patterns
│   ├── multi-machine.md                         # 250 lines - Machine-specific config architecture
│   └── auditing.md                              # 150 lines - Security auditing process
│
├── reference/                                   # Quick reference materials
│   ├── dotfiles-commands.md                     # 300 lines - dotfiles.sh command reference
│   └── quick-start.md                           # 100 lines - Quick start for new contributors
│
├── quality/                                     # Code & documentation quality
│   ├── code-standards.md                        # 150 lines - Code quality standards
│   └── documentation-standards.md               # 100 lines - Agent Rules compliance
│
├── adr/                                         # Architecture Decision Records
│   ├── README.md                                # ADR index
│   ├── template.md                              # ADR template
│   ├── 001-gnu-stow-for-symlinks.md
│   ├── 002-xdg-compliance.md
│   └── 003-native-tool-includes.md
│
└── plans/                                       # Improvement plans
    ├── README.md                                # Plan management guide (already exists)
    ├── template.md                              # Plan template (already exists)
    ├── 2026-01-improvement-plan.md              # This plan (already exists)
    └── docs-architecture-spec.md                # This file

Total: 15 main documentation files + supporting files
```

## New CLAUDE.md Structure (200 lines)

### Sections to Keep

```markdown
# Dotfiles Project Context for Claude

This is a bash/shell-based dotfiles management system for macOS using GNU Stow.

## Quick Reference (50 lines)

- Project type: Bash/Zsh dotfiles management system
- Platform: macOS (Darwin)
- Package manager: GNU Stow
- Security: GPG signing, SSH key validation
- Architecture: Distributed docs in docs/ and component AGENTS.md files

## Repository Navigation (30 lines)

**Core files:**
- dotfiles.sh - Main management script
- packages.config - Package list
- versions.config - Version requirements

**Documentation:**
- README.md - User documentation
- ARCHITECTURE.md - High-level design
- docs/ - Detailed development guides (THIS IS WHERE YOU FIND DETAILS)
- [component]/AGENTS.md - Component-specific implementation

**For detailed information:**
- Read ARCHITECTURE.md first for design principles
- Read docs/ files for specific topics
- Read component AGENTS.md for implementation details

## Finding Information - Decision Tree (50 lines)

**When working on...**

### Adding New Features
→ Read: `docs/development/adding-features.md` (CRITICAL - has checklist)
→ Use: product-manager agent for planning
→ Use: architecture-assistant agent for design

### GNU Stow Packages
→ Read: `docs/development/package-management.md`
→ Use: architecture-assistant agent

### Shell Scripts
→ Read: `docs/development/shell-patterns.md`
→ Read: `shell/AGENTS.md`
→ Use: shell-validator agent

### Security
→ Read: `docs/security/patterns.md`
→ Read: `docs/security/multi-machine.md`
→ Use: security-auditor agent

### Testing/Debugging
→ Read: `docs/development/testing-debugging.md`

### dotfiles.sh Commands
→ Read: `docs/reference/dotfiles-commands.md`

### Claude Code Integration
→ Read: `docs/development/claude-code-integration.md`

## Essential Rules (40 lines)

**Security (NEVER violate these):**
- NEVER commit credentials, API keys, or personal data
- ALWAYS use machine.config for personal data
- ALWAYS validate file permissions (600/700)
- ALWAYS use secure curl pattern

**Architecture (MUST follow these):**
- MUST use GNU Stow for package management
- MUST separate machine-specific from shared configs
- MUST use native tool includes for layering
- MUST update install/reinstall/update workflows when adding features

**Documentation (MUST maintain these):**
- MUST update docs/ when changing patterns
- MUST update component AGENTS.md for component changes
- MUST follow Agent Rules specification
- MUST verify links work after changes

## Key Commands (20 lines)

```bash
./dotfiles.sh status          # Check installation & version compliance
./dotfiles.sh reinstall       # Safe way to test package changes
./dotfiles.sh install         # Initial installation
./dotfiles.sh update          # Update Node.js, Go versions
```

## Sub-Agent Coordination (10 lines)

- **product-manager**: Feature planning & UX review
- **architecture-assistant**: Code architecture decisions
- **shell-validator**: Bash/zsh validation
- **security-auditor**: Security scanning
- **harness-architect**: Agent/docs design

Total: ~200 lines
```

## Content Mapping: CLAUDE.md → docs/

### docs/development/adding-features.md (200 lines)

**Priority**: HIGHEST - This is the critical feature integration checklist

**Content**:
```markdown
# Adding Features to Dotfiles

## Overview
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
- Adding Git config → Needs git installed, prompts for user.name/email
- Adding Neovim config → Needs nvim installed, auto-bootstraps plugins
- Adding SSH config → Needs ssh client, prompts for key selection

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
- Adding shell module → Goes in shell/ package, stowed to ~/
- Adding tool config → Create new package, add to packages.config
- Removing feature → Remove from packages.config, run reinstall

### 3. Update Support (MUST address)
- [ ] Does feature have updateable components?
  - Add to `dotfiles.sh update` if tool has versions
  - Document update process in component AGENTS.md
- [ ] Can users update without breaking setup?
  - Test upgrade path from previous version
  - Preserve user customizations
  - Migrate configs if format changes

**Examples:**
- Language version managers → Add to update command
- Plugin managers → Document how to update plugins
- Config format changes → Provide migration script

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
- Git config → User email in machine.config
- SSH config → Keys in ~/.config/ssh/machine.config
- New shell script → Validate & quote variables

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
- New package → Create package/AGENTS.md
- New workflow → Update docs/development/
- Architecture change → Update ARCHITECTURE.md, docs/architecture/

### 6. Testing (MUST complete)
- [ ] Installation tested?
  - `./dotfiles.sh status` passes
  - Feature installs on clean machine
- [ ] Complete cycle tested?
  - Install → Uninstall → Reinstall works
  - Update doesn't break feature
- [ ] Security validated?
  - No credentials in git status
  - File permissions correct
  - .gitignore covers sensitive files

**Examples:**
- Package testing → status, reinstall, verify symlinks
- Security testing → git status, ls -la ~/.config/
- Update testing → modify versions.config, run update

## Example: Adding Alacritty Terminal

### 1. Installation Support
```bash
# dotfiles.sh install
if ! command -v alacritty &> /dev/null; then
    echo "⚠️  Alacritty not found"
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
- ✅ Update README.md with alacritty section
- ✅ Create alacritty/AGENTS.md
- ✅ Update ARCHITECTURE.md (add to component list)

### 6. Testing
```bash
./dotfiles.sh status        # Should show alacritty properly stowed
./dotfiles.sh uninstall     # Remove symlinks
./dotfiles.sh reinstall     # Restore symlinks
ls -la ~/.config/alacritty/ # Verify symlink created
```

## Common Pitfalls

### ❌ Forgetting install/reinstall integration
**Problem**: Feature works on developer's machine, fails on fresh install.
**Solution**: Always test `./dotfiles.sh install` on clean machine.

### ❌ Putting machine-specific data in repo
**Problem**: Personal email/keys committed to git.
**Solution**: Use ~/.config/ machine.config pattern.

### ❌ Not testing the complete cycle
**Problem**: Feature breaks on reinstall or update.
**Solution**: Test install → uninstall → reinstall → update cycle.

### ❌ Skipping documentation
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
```

**When Agents Should Read This**:
- ALWAYS when planning to add new functionality
- ALWAYS when modifying install/reinstall/update commands
- Referenced by product-manager agent in every feature plan

**Cross-References**:
- docs/development/package-management.md (GNU Stow details)
- docs/security/patterns.md (Security requirements)
- docs/development/testing-debugging.md (Testing approaches)

### docs/development/package-management.md (250 lines)

**Source**: CLAUDE.md lines 152-380 (GNU Stow Package Management section)

**Content**:
- Package System Architecture
- Adding New Packages (step-by-step)
- Package Configuration Format
- Status Validation Logic
- Removing Packages
- Advanced Package Patterns
- Package Implementation Checklist
- Troubleshooting Stow conflicts

**When Agents Should Read This**:
- When creating new GNU Stow packages
- When modifying package structure
- When debugging Stow issues
- Referenced by architecture-assistant agent for package design

**Cross-References**:
- docs/development/adding-features.md (Feature integration)
- docs/reference/dotfiles-commands.md (status/reinstall commands)

### docs/development/shell-patterns.md (200 lines)

**Source**: Extracted from CLAUDE.md development patterns + shell/AGENTS.md references

**Content**:
- Bash/zsh best practices for this project
- Error handling patterns
- Variable quoting and validation
- Path resolution patterns
- Function design patterns
- Module structure and loading
- Performance optimization
- Common pitfalls and solutions

**When Agents Should Read This**:
- When writing or modifying shell scripts
- When reviewing shell code
- Referenced by shell-validator agent

**Cross-References**:
- shell/AGENTS.md (Shell architecture)
- docs/security/patterns.md (Security patterns)

### docs/development/version-management.md (150 lines)

**Source**: CLAUDE.md Version Management section + shell/AGENTS.md

**Content**:
- versions.config architecture
- How version validation works
- Adding new version requirements
- Update command implementation
- Version manager integration (NVM, GVM, Rustup)
- Troubleshooting version issues

**When Agents Should Read This**:
- When adding tools with version requirements
- When modifying update command
- When debugging version validation

**Cross-References**:
- docs/reference/dotfiles-commands.md (update command)
- shell/AGENTS.md (Version manager integration)

### docs/development/testing-debugging.md (150 lines)

**Source**: CLAUDE.md Testing Patterns + Debug Commands sections

**Content**:
- Testing Patterns (manual testing, validation checks)
- Debug Commands (shell debugging, Stow debugging, environment debugging)
- Testing install/reinstall/update cycle
- Testing on clean machines
- Debugging Stow conflicts
- Debugging shell startup issues
- Security testing patterns

**When Agents Should Read This**:
- When testing new features
- When debugging issues
- Referenced in feature integration checklist

**Cross-References**:
- docs/development/adding-features.md (Testing requirements)
- docs/reference/dotfiles-commands.md (Commands for testing)

### docs/development/macos-patterns.md (100 lines)

**Source**: CLAUDE.md macOS-Specific Considerations section

**Content**:
- Homebrew Integration patterns
- XDG Directory Handling on macOS
- Security on macOS (chmod, secure curl)
- macOS-specific commands (hostname, scutil)
- Differences from Linux

**When Agents Should Read This**:
- When adding macOS-specific functionality
- When handling XDG directories
- When using Homebrew

**Cross-References**:
- docs/development/shell-patterns.md (Shell patterns)

### docs/development/claude-code-integration.md (150 lines)

**Source**: CLAUDE.md Claude Code Configuration Management + Hooks sections

**Content**:
- .claude/settings.json configuration
- Permission management
- Hook configuration
- PostToolUse hooks
- Maintenance guidelines
- Security review process
- Hook development patterns

**When Agents Should Read This**:
- When modifying .claude/settings.json
- When developing new hooks
- When adding new permissions

**Cross-References**:
- claude_hooks/AGENTS.md (Hook development)
- docs/security/patterns.md (Security review)

### docs/security/overview.md (150 lines)

**Source**: CLAUDE.md Security Guidelines introduction + principles

**Content**:
- Security design principles
- Threat model for dotfiles
- Security architecture overview
- Security-first design approach
- Common security pitfalls
- Security validation workflow

**When Agents Should Read This**:
- When starting security-related work
- For understanding overall security posture

**Cross-References**:
- docs/security/patterns.md (Implementation details)
- docs/security/multi-machine.md (Machine isolation)
- docs/security/auditing.md (Validation process)

### docs/security/patterns.md (200 lines)

**Source**: CLAUDE.md Security Guidelines for Development section

**Content**:
- Credential Handling Rules
- Input Validation and Command Injection Prevention
- Permission Management Rules
- Secure Network Operations
- Code Review Security Checklist
- Security Testing patterns

**When Agents Should Read This**:
- When writing shell scripts
- When handling user input
- When adding network operations
- Referenced by security-auditor agent
- Referenced by shell-validator agent

**Cross-References**:
- docs/development/shell-patterns.md (Shell implementation)
- docs/security/multi-machine.md (Machine-specific configs)
- docs/security/auditing.md (Validation)

### docs/security/multi-machine.md (250 lines)

**Source**: CLAUDE.md Multi-Machine Configuration Architecture section

**Content**:
- Design Rationale (why separate configs)
- Layered Configuration Implementation
  - Git Configuration Layering
  - SSH Configuration Layering
- XDG Directory Usage
- Installation Workflow for Machine-Specific Configs
- Verification and Validation
- Testing Multi-Machine Configuration
- Security Considerations for Multi-Machine Setup

**When Agents Should Read This**:
- When working with machine-specific configs
- When adding tools that need personal data
- When modifying install workflow

**Cross-References**:
- docs/security/patterns.md (Security implementation)
- docs/reference/dotfiles-commands.md (install command)
- git/AGENTS.md, ssh/AGENTS.md (Implementation details)

### docs/security/auditing.md (150 lines)

**Source**: CLAUDE.md Security Testing + Known Security Issues sections

**Content**:
- Security audit process
- Automated security checks
- Manual security review checklist
- Known security issues and fixes
- Security testing commands
- Periodic audit guidelines

**When Agents Should Read This**:
- When running security audits
- When fixing security issues
- Referenced by security-auditor agent

**Cross-References**:
- docs/security/patterns.md (Patterns to check)
- shell/AGENTS.md (Known shell security issues)

### docs/reference/dotfiles-commands.md (300 lines)

**Source**: CLAUDE.md dotfiles.sh Command Reference section

**Content**:
- Command Overview
- install Command (purpose, workflow, usage)
- status Command (purpose, validation logic, output format)
- update Command (purpose, workflow, version managers)
- reinstall Command (purpose, workflow, use cases)
- uninstall Command (purpose, workflow, behavior)
- help Command
- Implementation Details (error handling, dependency checking)

**When Agents Should Read This**:
- When using dotfiles.sh commands
- When modifying command implementations
- Quick reference for what each command does

**Cross-References**:
- docs/development/adding-features.md (Integration requirements)
- docs/development/package-management.md (How commands use Stow)
- docs/security/multi-machine.md (install command machine config)

### docs/reference/quick-start.md (100 lines)

**New Content**:
- New contributor onboarding
- Quick architecture overview
- Most common tasks
- Key files to read first
- Development workflow overview

**When Agents Should Read This**:
- When onboarding new contributors
- Quick project orientation

### docs/quality/code-standards.md (150 lines)

**Source**: CLAUDE.md Code Quality Standards section

**Content**:
- Shell scripting standards
- Variable quoting requirements
- Error handling patterns
- Dependency checking patterns
- Performance guidelines
- Security requirements
- Examples of good and bad patterns

**When Agents Should Read This**:
- When writing shell code
- When reviewing code
- Referenced by shell-validator agent

**Cross-References**:
- docs/development/shell-patterns.md (Implementation patterns)
- docs/security/patterns.md (Security patterns)

### docs/quality/documentation-standards.md (100 lines)

**Source**: CLAUDE.md Documentation Architecture section

**Content**:
- Agent Rules Compliance requirements
- Documentation maintenance rules
- When to update which docs
- RFC 2119 keyword usage
- Flat bullet list format
- Code example standards

**When Agents Should Read This**:
- When writing documentation
- When updating AGENTS.md files
- Referenced by documentation-reviewer agent (future)

**Cross-References**:
- docs/architecture/documentation-strategy.md (Overall strategy)

### docs/architecture/overview.md (150 lines)

**Source**: Condensed version of ARCHITECTURE.md with links to detailed docs

**Content**:
- High-level system design summary
- Key architectural principles
- Component overview
- Integration points
- Links to detailed docs for each area

**When Agents Should Read This**:
- For high-level architecture understanding
- Before diving into specific areas

**Cross-References**:
- ARCHITECTURE.md (Full architectural documentation)
- docs/architecture/documentation-strategy.md
- All component AGENTS.md files

### docs/architecture/documentation-strategy.md (100 lines)

**Source**: This specification file (implementation summary)

**Content**:
- What goes in CLAUDE.md vs docs/ vs AGENTS.md
- How agents access documentation
- Documentation maintenance workflow
- When to update which files
- Navigation strategy

**When Agents Should Read This**:
- When updating documentation
- When unsure where something belongs
- For understanding doc structure

**Cross-References**:
- CLAUDE.md (Primary context)
- docs/quality/documentation-standards.md (Standards)

### docs/architecture/agent-integration.md (150 lines)

**New Content**:
- How sub-agents use docs/
- Agent coordination patterns
- Which agent reads which docs
- Agent delegation workflow
- Context management strategy

**When Agents Should Read This**:
- For understanding how to access documentation
- When coordinating with other agents

**Cross-References**:
- .claude/agents/README.md (Agent catalog)
- docs/architecture/documentation-strategy.md

### docs/README.md (100 lines)

**New Content**:

```markdown
# Documentation Guide

This directory contains detailed development, security, and architecture documentation for the dotfiles repository.

## For AI Agents

This docs/ structure is designed for modular context loading. Instead of reading all 1,400+ lines of CLAUDE.md, read only the specific docs you need for your task.

### Quick Navigation by Task

**Adding new features?**
→ Start with: `docs/development/adding-features.md` (has critical checklist)
→ Then: `docs/development/package-management.md` (if adding package)

**Working with shell scripts?**
→ Read: `docs/development/shell-patterns.md`
→ And: `docs/security/patterns.md` (security requirements)

**Security review?**
→ Read: `docs/security/patterns.md`
→ And: `docs/security/auditing.md`

**Architecture decisions?**
→ Read: `docs/architecture/overview.md`
→ Then: Specific area docs as needed

**Command implementation?**
→ Read: `docs/reference/dotfiles-commands.md`

## For Human Contributors

### Getting Started
1. Read `README.md` in repository root (user documentation)
2. Read `ARCHITECTURE.md` (high-level design principles)
3. Read `CLAUDE.md` (AI agent context - quick reference)
4. Dive into `docs/` for detailed guidance

### Directory Structure

- **architecture/** - High-level system design and documentation strategy
- **development/** - Development guides and patterns
- **security/** - Security patterns and guidelines
- **reference/** - Quick reference materials
- **quality/** - Code and documentation quality standards
- **adr/** - Architecture Decision Records
- **plans/** - Improvement plans and roadmaps

## Documentation Philosophy

### What Goes Where

**CLAUDE.md** (200 lines):
- Quick reference and navigation
- Essential rules that apply everywhere
- Decision tree for finding information
- Links to detailed docs/

**docs/** (this directory):
- Detailed development guides
- Comprehensive patterns and examples
- Security guidelines
- Architecture deep-dives

**ARCHITECTURE.md**:
- High-level design principles
- Why architectural choices were made
- Component relationships

**Component AGENTS.md** (e.g., shell/AGENTS.md):
- Component-specific implementation
- Integration points
- Technical details

## Maintenance

When making changes:
- Update the most specific documentation first (component AGENTS.md)
- Update relevant docs/ files
- Update CLAUDE.md if patterns change
- Keep documentation current with code

See `docs/quality/documentation-standards.md` for detailed guidelines.
```

## Agent Access Patterns

### How Different Agents Use docs/

#### product-manager Agent
**Always reads first**:
- `docs/development/adding-features.md` (feature checklist)

**Reads as needed**:
- `docs/development/package-management.md` (understanding Stow)
- `docs/security/patterns.md` (security requirements)
- `docs/reference/dotfiles-commands.md` (workflow commands)

**Delegation pattern**:
```markdown
1. User: "I want to add feature X"
2. product-manager reads adding-features.md
3. product-manager creates feature-specific checklist
4. product-manager delegates to architecture-assistant for design
5. product-manager delegates to security-auditor for security review
6. product-manager validates complete workflow
```

#### architecture-assistant Agent
**Always reads first**:
- `docs/architecture/overview.md` (system architecture)

**Reads as needed**:
- `docs/development/package-management.md` (GNU Stow patterns)
- `docs/security/multi-machine.md` (config layering)
- `docs/development/shell-patterns.md` (shell module design)

**Usage pattern**:
```markdown
1. User: "How should I structure this package?"
2. architecture-assistant reads overview.md + package-management.md
3. architecture-assistant provides design recommendations
4. architecture-assistant documents decision in component AGENTS.md
```

#### shell-validator Agent
**Always reads first**:
- `docs/development/shell-patterns.md` (shell best practices)
- `docs/security/patterns.md` (security requirements)

**Reads as needed**:
- `docs/quality/code-standards.md` (quality requirements)

**Usage pattern**:
```markdown
1. User: "Validate this shell script"
2. shell-validator reads shell-patterns.md + patterns.md
3. shell-validator runs shellcheck
4. shell-validator checks project-specific patterns
5. shell-validator reports issues with fixes
```

#### security-auditor Agent
**Always reads first**:
- `docs/security/patterns.md` (security patterns)
- `docs/security/auditing.md` (audit process)

**Reads as needed**:
- `docs/security/multi-machine.md` (machine config isolation)
- `docs/development/shell-patterns.md` (shell security)

**Usage pattern**:
```markdown
1. User: "Audit this feature for security"
2. security-auditor reads patterns.md + auditing.md
3. security-auditor scans for common issues
4. security-auditor validates permissions
5. security-auditor checks .gitignore coverage
6. security-auditor reports findings with severity
```

### Context Loading Strategy

**Primary Claude Code Session**:
1. Loads CLAUDE.md (200 lines) automatically
2. CLAUDE.md provides navigation map
3. Claude reads specific docs/ files as needed for task
4. Example: Adding feature → reads adding-features.md → reads package-management.md

**Sub-Agent Sessions**:
1. Sub-agent receives task from main session
2. Sub-agent's instructions specify which docs/ files to read
3. Sub-agent reads only necessary docs (task-specific)
4. Sub-agent returns results to main session

**Example Flow**:
```
User: "Add Alacritty configuration"
Main Claude: Reads CLAUDE.md (200 lines)
Main Claude: Sees "adding features → product-manager agent"
Main Claude: Invokes product-manager agent

product-manager: Reads adding-features.md (200 lines)
product-manager: Creates integration checklist
product-manager: Delegates to architecture-assistant

architecture-assistant: Reads package-management.md (250 lines)
architecture-assistant: Designs package structure
architecture-assistant: Returns design to product-manager

product-manager: Validates design against checklist
product-manager: Returns plan to user

Total context: ~650 lines vs 1,433 lines (55% reduction)
```

## Implementation Order

### Phase 1: Foundation (Week 1)
1. **Create directory structure**
   ```bash
   mkdir -p docs/{architecture,development,security,reference,quality,adr}
   ```

2. **Create docs/README.md**
   - Navigation guide for agents and humans
   - What goes where explanation

3. **Create docs/architecture/documentation-strategy.md**
   - Implementation of this specification
   - Maintenance guidelines

### Phase 2: Critical Content (Week 1-2)
4. **Create docs/development/adding-features.md** ⭐ HIGHEST PRIORITY
   - Feature integration checklist
   - Install/reinstall/update/security requirements
   - Examples and common pitfalls

5. **Extract docs/development/package-management.md**
   - From CLAUDE.md GNU Stow section
   - Add cross-references

6. **Extract docs/security/patterns.md**
   - From CLAUDE.md Security Guidelines section
   - Add cross-references

7. **Extract docs/security/multi-machine.md**
   - From CLAUDE.md Multi-Machine Configuration section
   - Add cross-references

### Phase 3: Reference & Development (Week 2)
8. **Extract docs/reference/dotfiles-commands.md**
   - From CLAUDE.md Command Reference section

9. **Extract docs/development/shell-patterns.md**
   - From CLAUDE.md development patterns + shell/AGENTS.md

10. **Create docs/development/testing-debugging.md**
    - From CLAUDE.md Testing + Debug sections

11. **Create docs/development/version-management.md**
    - From CLAUDE.md + shell/AGENTS.md

### Phase 4: Remaining Docs (Week 3)
12. **Create remaining docs/ files**
    - docs/development/macos-patterns.md
    - docs/development/claude-code-integration.md
    - docs/security/overview.md
    - docs/security/auditing.md
    - docs/architecture/overview.md
    - docs/architecture/agent-integration.md
    - docs/reference/quick-start.md
    - docs/quality/code-standards.md
    - docs/quality/documentation-standards.md

### Phase 5: CLAUDE.md Restructure (Week 3)
13. **Rewrite CLAUDE.md**
    - Reduce to 200 lines
    - Quick reference format
    - Navigation decision tree
    - Essential rules only
    - Links to docs/ for details

14. **Update agent instructions**
    - Update product-manager.md to reference docs/
    - Update architecture-assistant.md to reference docs/
    - Update shell-validator.md to reference docs/
    - Update security-auditor.md to reference docs/

### Phase 6: Validation (Week 4)
15. **Test with agents**
    - Test product-manager feature planning workflow
    - Test architecture-assistant package design
    - Test shell-validator script validation
    - Test security-auditor security scanning

16. **Verify context reduction**
    - Measure token usage before/after
    - Verify 60-70% reduction achieved

17. **Update references**
    - Verify all documentation links work
    - Update any references to old CLAUDE.md sections
    - Update component AGENTS.md files to reference docs/

## Expected Benefits

### Context Consumption
- **Before**: 1,433 lines of CLAUDE.md loaded every time
- **After**: 200 lines of CLAUDE.md + task-specific docs (~200-400 lines)
- **Reduction**: 60-70% in typical scenarios

### Discoverability
- Clear navigation in CLAUDE.md decision tree
- Task-oriented organization
- Quick reference for common scenarios

### Maintainability
- Each doc file is focused (100-200 lines typical)
- Changes affect only relevant docs
- Easier to keep current

### Agent Effectiveness
- Agents read only what they need
- Clear instructions on what to read
- Better coordination between agents
- Enforced feature integration workflow

### Developer Experience
- Easy to find information
- Clear guidance for common tasks
- Feature checklist prevents mistakes
- Better onboarding

## Success Criteria

### Quantitative
- [ ] CLAUDE.md reduced to ≤ 200 lines (from 1,433)
- [ ] 15+ docs/ files created (focused, task-oriented)
- [ ] All content from old CLAUDE.md preserved in docs/
- [ ] Context consumption reduced by 60-70% in typical scenarios
- [ ] All documentation links work

### Qualitative
- [ ] Agents can quickly find relevant docs for tasks
- [ ] Feature integration checklist is comprehensive
- [ ] Navigation is intuitive (agents and humans)
- [ ] Documentation is maintainable (small, focused files)
- [ ] New contributors can quickly orient

### Validation
- [ ] product-manager agent successfully uses adding-features.md
- [ ] architecture-assistant agent successfully uses package-management.md
- [ ] shell-validator agent successfully uses shell-patterns.md
- [ ] security-auditor agent successfully uses security docs
- [ ] Feature addition workflow tested end-to-end with agents

## Open Questions for Feedback

### Structure
- [ ] Approve overall docs/ directory structure?
- [ ] Adjust any subdirectory organization?
- [ ] Add or remove any doc files?

### Content
- [ ] Is docs/development/adding-features.md comprehensive enough?
- [ ] Should any sections be split further?
- [ ] Should any sections be combined?

### Implementation
- [ ] Approve implementation order?
- [ ] Adjust timeline (4 weeks)?
- [ ] Should we implement in phases or all at once?

### Agent Integration
- [ ] Is agent access pattern clear?
- [ ] Should agents read different docs?
- [ ] Need clarification on agent coordination?

## Next Steps

After approval:
1. Begin Phase 1 (foundation)
2. Implement critical content (adding-features.md first)
3. Extract content from CLAUDE.md systematically
4. Restructure CLAUDE.md
5. Update agent instructions
6. Test with agents
7. Validate success criteria

---

**Status**: Draft - Awaiting Review and Approval
**Feedback Requested By**: 2026-01-05
**Implementation Start**: Upon approval
