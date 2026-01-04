# Architecture Overview

This document provides a high-level summary of the dotfiles system architecture. For detailed design principles and rationale, see ARCHITECTURE.md in the repository root.

## System Architecture Summary

### Core Architecture Principles

**GNU Stow for symlink management:**
- Package-based organization
- Configuration-driven installation
- Mirrors target filesystem structure
- Atomic install/uninstall operations

**Machine-specific configuration isolation:**
- Shared configs in repository (Git aliases, SSH patterns)
- Personal data in ~/.config/ (Git identity, SSH keys)
- Native tool includes for layering
- XDG directory compliance

**Security-first design:**
- Credentials never in repository
- Automated permission validation
- GPG signing required for commits
- SSH key authentication only

**Performance optimization:**
- Lazy loading of shell modules
- Cached expensive operations
- Source guards prevent duplicate loading
- Minimal shell startup overhead

## Component Overview

### Package Management (GNU Stow)
- **Location:** dotfiles.sh, packages.config
- **Purpose:** Symlink management for all configurations
- **Integration:** All tool configs are packages
- **Details:** docs/development/package-management.md

### Shell Configuration
- **Location:** shell/ directory
- **Purpose:** Modular Zsh configuration
- **Integration:** Sources all tool configs
- **Details:** shell/AGENTS.md

### Tool Configurations
- **Git:** git/ - Layered configuration with native includes
- **SSH:** ssh/ - Security configuration with machine-specific keys
- **Neovim:** nvim/ - LSP and plugin configuration
- **Tmux:** tmux/ - Session management and key bindings
- **Starship:** starship/ - Prompt configuration

### Security Layer
- **Machine configs:** ~/.config/{git,ssh}/machine.config
- **Permission validation:** shell/security.sh
- **Credential isolation:** .gitignore coverage
- **Details:** docs/security/

### Version Management
- **Location:** versions.config
- **Purpose:** Centralized version requirements
- **Integration:** dotfiles.sh status validation
- **Details:** docs/development/version-management.md

### Claude Code Integration
- **Location:** .claude/, claude_hooks/
- **Purpose:** AI assistant configuration
- **Integration:** Custom hooks, sub-agents
- **Details:** docs/development/claude-code-integration.md

## Integration Points

### Shell → Tools
- Shell sources tool-specific configurations
- Tools add to PATH, set aliases, configure environment
- Lazy loading for performance

### dotfiles.sh → Stow
- dotfiles.sh reads packages.config
- Calls GNU Stow for symlink management
- Validates installation with Stow dry-run

### Base Config → Machine Config
- Git [include] directive loads machine.config
- SSH Include directive loads machine.config
- Tools use XDG directories for machine-specific data

### Install → Security
- Install prompts for Git identity
- Install scans for SSH keys
- Install generates machine.config files
- Install validates permissions

### Status → Validation
- Status checks version compliance
- Status validates Stow packages
- Status checks Claude hooks
- Status verifies security

## Data Flow

### Installation Flow
```
User runs: ./dotfiles.sh install
  ↓
Check dependencies (git, stow, etc.)
  ↓
Prompt for Git identity (name, email)
  ↓
Scan for SSH keys
  ↓
Scan for GPG keys
  ↓
Generate ~/.config/git/machine.config
Generate ~/.config/ssh/machine.config
  ↓
Read packages.config
  ↓
For each package:
  GNU Stow creates symlinks
  ↓
Validate installation
  ↓
Done
```

### Shell Startup Flow
```
User opens shell
  ↓
Load ~/.zshrc (symlink to shell/.zshrc)
  ↓
Source shell modules in order:
  - path-resolution.sh (set paths)
  - utils.sh (common functions)
  - security.sh (validate permissions)
  - tool configs (git, ssh, etc.)
  ↓
Initialize prompt (starship)
  ↓
Ready for use
```

### Package Update Flow
```
User modifies package in repository
  ↓
User runs: ./dotfiles.sh reinstall
  ↓
Unstow all packages
  ↓
Read packages.config
  ↓
Stow only packages in config
  ↓
Symlinks updated
  ↓
Done
```

## Security Architecture

### Credential Isolation
- **Repository:** Tool configurations, no personal data
- **~/.config/:** Machine-specific configs with credentials
- **.gitignore:** Ensures machine configs never committed

### Permission Model
- **600:** SSH private keys, sensitive machine configs
- **700:** SSH directory, GPG directory, socket directories
- **644:** Shared configs without secrets
- **755:** Executables

### Validation
- **Install time:** Dependency checks, permission validation
- **Shell startup:** Security validation runs automatically
- **Status command:** Comprehensive validation on demand

## Performance Characteristics

### Shell Startup
- **Target:** <100ms from shell start to prompt
- **Optimization:** Lazy loading, caching, source guards
- **Trade-offs:** Functionality vs startup time

### Package Operations
- **Status:** O(n) where n = number of packages (fast, dry-run only)
- **Reinstall:** O(n) symlink operations (moderate)
- **Install:** O(n) + user interaction (one-time cost)

## Design Trade-offs

### GNU Stow vs Manual Symlinks
- **Chosen:** GNU Stow
- **Rationale:** Atomic operations, conflict detection, easy removal
- **Trade-off:** Extra dependency, learning curve

### Native Includes vs Scripts
- **Chosen:** Native tool includes (Git [include], SSH Include)
- **Rationale:** Tool-native, no wrapper scripts, portable
- **Trade-off:** Requires tool support for includes

### XDG vs Home Directory
- **Chosen:** XDG directories for machine configs
- **Rationale:** Standard, organized, respects user preferences
- **Trade-off:** Slightly more complex paths

### Modular vs Monolithic Shell
- **Chosen:** Modular shell configuration
- **Rationale:** Maintainable, testable, reusable
- **Trade-off:** More files to manage

## For More Details

- **Design principles:** Read ARCHITECTURE.md
- **GNU Stow patterns:** Read docs/development/package-management.md
- **Security architecture:** Read docs/security/overview.md
- **Shell architecture:** Read shell/AGENTS.md
- **Component details:** Read [component]/AGENTS.md

## Cross-References

- ARCHITECTURE.md (Full architectural documentation)
- docs/architecture/documentation-strategy.md (How docs are organized)
- docs/architecture/agent-integration.md (How AI agents use this system)
- All component AGENTS.md files (Implementation details)
