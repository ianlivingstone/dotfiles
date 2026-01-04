# Documentation Guide

This directory contains detailed development, security, and architecture documentation for the dotfiles repository.

## For AI Agents

This docs/ structure is designed for modular context loading. Instead of reading all 1,400+ lines of CLAUDE.md, read only the specific docs you need for your task.

### Quick Navigation by Task

**Adding new features?**
- Start with: `docs/development/adding-features.md` (has critical checklist)
- Then: `docs/development/package-management.md` (if adding package)

**Working with shell scripts?**
- Read: `docs/development/shell-patterns.md`
- And: `docs/security/patterns.md` (security requirements)

**Security review?**
- Read: `docs/security/patterns.md`
- And: `docs/security/auditing.md`

**Architecture decisions?**
- Read: `docs/architecture/overview.md`
- Then: Specific area docs as needed

**Command implementation?**
- Read: `docs/reference/dotfiles-commands.md`

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
