# Jujutsu (jj) Configuration Architecture

**📋 Agent Rules Compliance**: This file follows Agent Rules specification using imperative statements with RFC 2119 keywords and flat bullet list format.

## Overview
The jj package provides configuration for Jujutsu, a Git-compatible version control system that works **on top of git repositories**. Git remains the source of truth and collaboration layer, while jj provides a superior UX for complex workflows through automatic commit management and a more intuitive mental model.

**Key principle**: jj is a front-end to git, not a replacement. All commits live in git, and you can use git and jj commands interchangeably on the same repository.

## Design Principles
- MUST work on top of git repositories with git as source of truth
- MUST support colocated repositories (jj and git sharing the same .git directory)
- MUST integrate seamlessly with existing git workflows and remotes
- MUST provide sensible defaults that work across all machines
- MUST integrate with existing git configuration for user identity
- SHOULD use nvim as the default editor (consistent with dotfiles)
- SHOULD provide helpful aliases for common workflows (including git interop)
- MUST enable Git interoperability features and abandon unreachable commits
- MAY be customized per-machine by editing local config after stowing

## Configuration Architecture

### File Structure
```
jj/
├── config.toml            # Main jj configuration (symlinked to ~/.config/jj/config.toml)
└── AGENTS.md              # This architecture documentation
```

### Configuration Sections

**User Identity (`[user]`):**
- MUST set name and email for commit authorship
- SHOULD match git configuration values
- MAY be overridden locally after initial setup

**UI Settings (`[ui]`):**
- MUST use delta as pager for enhanced diff viewing
- MUST use nvim as default editor (consistent with dotfiles)
- SHOULD enable relative timestamps for better readability
- MUST use git-compatible diff format for interoperability

**Colors (`[colors]`):**
- MUST enable colors for terminal output
- SHOULD use default jj color scheme

**Aliases (`[aliases]`):**
- MUST provide common git-like aliases for familiarity (st, co, d, l)
- SHOULD provide jj-specific workflow aliases (sp, sq, n, e)
- MUST include graph visualization aliases (graph, lg)
- MAY be extended with custom aliases as needed

**Git Integration (`[git]`):**
- MUST enable auto-local-branch for git compatibility
- SHOULD use empty push-branch-prefix for clean branch names
- MUST enable abandon-unreachable-commits to clean up rewritten commits
- MUST maintain Git interoperability for hybrid workflows
- MUST support colocated repositories (shared .git directory)
- SHOULD work transparently with git remotes and branches

**Merge Tools (`[merge-tools]`):**
- MUST configure vimdiff with nvim as merge tool
- SHOULD use sensible defaults for 3-way merge layout
- MAY be customized for preferred merge workflow

## Installation

### Prerequisites
- MUST have jj installed via Homebrew: `brew install jj`
- SHOULD have delta installed for enhanced diffs: `brew install git-delta`
- MUST have nvim installed (provided by dotfiles)
- SHOULD have git configured for identity fallback

### Installation Steps
```bash
# Install jj via Homebrew
brew install jj

# Install delta for better diffs (recommended)
brew install git-delta

# Stow will symlink config.toml to ~/.config/jj/config.toml
./dotfiles.sh reinstall

# Verify configuration
jj config list

# Initialize jj in an existing git repository (colocated mode)
cd /path/to/your/git/repo
jj git init --colocate  # jj and git share the same .git directory

# Or just start using jj - it auto-detects git repos
jj status  # Works in any git repository
```

## Integration Points

### Git Integration (Colocated Repositories)
- MUST work on top of git repositories (git is source of truth)
- MUST use colocated mode (shared .git directory, no separate jj storage)
- MUST work seamlessly with git commands in the same repository
- SHOULD coexist with git workflows - use git and jj commands interchangeably
- MUST respect .gitignore files
- MUST use git remotes for push/pull operations (jj git push, jj git fetch)
- MUST sync with git state - commits created with jj are real git commits
- SHOULD handle git operations performed outside jj gracefully

### Editor Integration
- MUST use nvim from dotfiles configuration
- SHOULD inherit nvim keybindings and plugins
- MUST respect nvim as merge tool

### Dotfiles Integration
- MUST be managed via GNU Stow like other packages
- MUST be listed in packages.config with XDG path
- SHOULD have version requirement in versions.config
- MUST validate installation in dotfiles.sh status

## Key Concepts

### Colocated Repository Model
This configuration uses **colocated mode** where jj and git share the same `.git` directory:
- **Single source of truth**: All commits live in git's object database
- **Full compatibility**: Git and jj commands work on the same commits
- **No duplication**: No separate jj storage, everything is git
- **Team friendly**: Teammates can use git while you use jj
- **Safety**: Can always fall back to pure git if needed

### Jujutsu Mental Model
- **Automatic commits**: Every change creates a commit automatically
- **Change IDs**: Changes are tracked independently of commits
- **No staging area**: Work directly with the working copy
- **Automatic rebasing**: Descendants update automatically
- **Conflict markers**: Conflicts are first-class objects
- **Git integration**: All jj commits are real git commits

### Common Workflows

**Initial setup in existing git repo:**
```bash
cd /path/to/git/repo
jj git init --colocate  # Enable jj in the repo (shares .git directory)
# Now use jj and git commands interchangeably
```

**Starting a new change:**
```bash
jj new              # Create new change on top of current commit
jj desc "message"   # Describe the change
# Work is auto-committed as you make changes
```

**Viewing history:**
```bash
jj st               # Status
jj l                # Log (last 10 commits)
jj graph            # Visual graph
git log             # Still works! git and jj see the same commits
```

**Splitting and squashing:**
```bash
jj split            # Split current change
jj sq               # Squash into parent
# Git commits are updated automatically
```

**Working with git remotes:**
```bash
jj fetch            # Fetch from git remote (alias for jj git fetch)
jj push             # Push to git remote (alias for jj git push)
jj sync             # Fetch from all remotes

# Or use git commands directly
git fetch origin
git push origin main
# jj automatically syncs with git state
```

**Mixing git and jj:**
```bash
# Use jj for complex rebasing
jj rebase -d main

# Use git for simple operations
git status
git log

# Switch back to jj
jj st
# Everything stays in sync!
```

## Customization

### Local Overrides
To customize jj configuration after installation:
```bash
# Edit the stowed config directly
nvim ~/.config/jj/config.toml

# Or create a local override (advanced)
nvim ~/.config/jj/config-local.toml
# Then add to config.toml: include = "config-local.toml"
```

### Adding Custom Aliases
Add to `[aliases]` section in config.toml:
```toml
[aliases]
my-alias = ["command", "args"]
```

### Changing Default Editor
Modify `[ui]` section:
```toml
[ui]
editor = "code --wait"  # Use VS Code instead of nvim
```

## Validation

### Configuration Validation
```bash
# Verify config loads without errors
jj config list

# Check specific setting
jj config get ui.editor

# Validate aliases work
jj st  # Should run 'jj status'
```

### Integration Testing
```bash
# Test git interoperability
cd /tmp && git init test-repo && cd test-repo
jj init --git-repo=.
echo "test" > file.txt
jj desc "Test commit"
jj git push  # Should fail gracefully (no remote)
```

## Troubleshooting

### Config Not Loading
- MUST verify config.toml is at `~/.config/jj/config.toml`
- MUST check file permissions are readable
- SHOULD run `jj config list` to see active configuration

### Editor Not Working
- MUST verify nvim is in PATH: `which nvim`
- SHOULD check `jj config get ui.editor`
- MAY set EDITOR environment variable as fallback

### Git Integration Issues
- MUST be in a git repository: `git rev-parse --git-dir`
- SHOULD initialize jj in existing git repo: `jj init --git-repo=.`
- MAY need to fetch: `jj git fetch`

## Security Considerations

### Commit Signing
- SHOULD configure GPG signing if using jj as primary VCS
- MAY inherit GPG configuration from git setup
- MUST ensure signing key is available in GPG agent

**To enable GPG signing:**
```toml
[user]
name = "Your Name"
email = "email@example.com"

[git]
# Add GPG signing configuration
```

### Credential Management
- MUST use git credential helpers for authentication
- SHOULD leverage existing SSH keys for git remotes
- MUST NOT store credentials in config.toml

## Version Requirements
- MUST have jj >= 0.9.0 for template support
- SHOULD have delta >= 0.16 for optimal diff viewing
- MUST have nvim >= 0.9 (from dotfiles)

## References
- [Jujutsu Documentation](https://github.com/martinvonz/jj)
- [Jujutsu Tutorial](https://github.com/martinvonz/jj/blob/main/docs/tutorial.md)
- [Git Compatibility](https://github.com/martinvonz/jj/blob/main/docs/git-compatibility.md)
