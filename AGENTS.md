# AI Agent Rules for Dotfiles Project

**📋 Agent Rules Specification Compliance**: This file follows the Agent Rules specification for AI coding agents. All AI guidance files in this project (AGENTS.md, CLAUDE.md, ARCHITECTURE.md, and component AGENTS.md files) MUST follow Agent Rules format.

**🤖 Agent Support**: This project provides first-class support for Claude Code with compatibility for other Agent Rules compliant AI coding assistants.

## Quick Reference for AI Agents

**🎯 PRIMARY DOCUMENTATION**: Read [`CLAUDE.md`](CLAUDE.md) for comprehensive development guidelines, security patterns, and bash-specific conventions.

**🏗️ ARCHITECTURE**: Read [`ARCHITECTURE.md`](ARCHITECTURE.md) for project structure and distributed documentation approach.

## Essential Rules

### MUST Read First
- [`CLAUDE.md`](CLAUDE.md) - Complete project context, bash patterns, security guidelines
- [`ARCHITECTURE.md`](ARCHITECTURE.md) - Project structure and component relationships
- [`versions.config`](versions.config) - Tool version requirements
- Component `AGENTS.md` files before modifying that component

### MUST Follow Security Patterns  
- All commits and tags MUST be GPG signed
- Machine-specific data NEVER committed to git repository
- Use strict mode (`set -euo pipefail`) for installation scripts only
- Use graceful error handling (no `set -e`) for sourced shell modules
- Quote all variables and validate input

### MUST Use Centralized Patterns
- Version management via `get_version_requirement()` from `versions.config`
- Utility functions from `shell/utils.sh`
- Configuration layering: shared in git, machine-specific in `~/.config/`

### MUST Update Documentation
- Read existing component `AGENTS.md` files to understand current patterns before changes
- Update component's `AGENTS.md` file when modifying that component
- Update `ARCHITECTURE.md` for high-level architectural changes
- Keep documentation current with code changes

### MUST Test Changes
- Run `./dotfiles.sh status` to validate installation and version compliance
- Test individual shell modules with `source shell/module.sh`

### NEVER Do These
- Use `set -e` in sourced shell modules (breaks user shells)
- Hardcode versions or paths (use centralized management)
- Use `eval` on user input (command injection risk)
- Bypass security patterns documented in `CLAUDE.md`

## Component Architecture
Each directory has detailed architecture in its `AGENTS.md` file:
- [`shell/AGENTS.md`](shell/AGENTS.md) - Shell configuration architecture
- [`nvim/AGENTS.md`](nvim/AGENTS.md) - Neovim configuration architecture  
- [`git/AGENTS.md`](git/AGENTS.md) - Git configuration architecture
- [`ssh/AGENTS.md`](ssh/AGENTS.md) - SSH configuration architecture
- [`tmux/AGENTS.md`](tmux/AGENTS.md) - Tmux configuration architecture

## Agent Rules Format Requirements
All AI guidance files in this project MUST follow Agent Rules specification:
- MUST use imperative statements with RFC 2119 keywords (MUST, SHOULD, MAY, NEVER)
- MUST structure as flat bullet lists for scannability  
- MUST be concise and actionable
- SHOULD reference detailed documentation files rather than duplicating content

## Agent Compatibility

### First-Class Support
- **Claude Code**: Primary development environment with comprehensive `CLAUDE.md` documentation
- **Agent Rules specification**: All documentation follows standard format for broad compatibility

### Compatibility Notes
- **Cursor**: Can use this AGENTS.md as `.cursorrules` equivalent
- **Continue**: Compatible via Agent Rules specification adherence
- **Other agents**: Any agent supporting Agent Rules specification format