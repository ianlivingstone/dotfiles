# GitHub CLI (gh) Configuration Architecture

**📋 Agent Rules Compliance**: This file follows Agent Rules specification using imperative statements with RFC 2119 keywords and flat bullet list format.

## Overview
The gh package provides configuration for GitHub CLI, the official command-line tool for GitHub. It enables git-like workflow for GitHub operations including pull requests, issues, and repositories.

## Design Principles
- MUST use SSH protocol for git operations (consistent with dotfiles security)
- MUST use nvim as default editor (consistent with dotfiles)
- SHOULD use delta as pager for enhanced output viewing
- SHOULD provide helpful aliases for common workflows
- MUST maintain compatibility with git configuration
- MAY be customized per-machine after stowing

## Configuration Architecture

### File Structure
```
gh/
├── config.yml            # Main gh configuration (symlinked to ~/.config/gh/config.yml)
└── AGENTS.md             # This architecture documentation
```

### Configuration Sections

**Git Protocol (`git_protocol`):**
- MUST use ssh for security and key-based authentication
- SHOULD match git configuration protocol
- MUST work with existing SSH keys

**Editor (`editor`):**
- MUST use nvim as default editor (consistent with dotfiles)
- SHOULD inherit nvim configuration from dotfiles
- MUST work for commit messages, PR descriptions, etc.

**Pager (`pager`):**
- MUST use delta for enhanced diff viewing
- SHOULD use same pager as git and jj
- MUST provide syntax highlighting and line numbers

**Aliases (`aliases`):**
- MUST provide common workflow shortcuts (co, pv, pc, etc.)
- SHOULD follow git-like naming conventions
- MAY be extended with custom aliases as needed

**Prompt (`prompt`):**
- MUST enable prompts for confirmation
- SHOULD prevent accidental operations
- MAY be disabled for scripting use cases

## Installation

### Prerequisites
- MUST have gh installed via Homebrew: `brew install gh`
- SHOULD have delta installed for pager: `brew install git-delta`
- MUST have nvim installed (provided by dotfiles)
- MUST have SSH keys configured for GitHub

### Installation Steps
```bash
# Install gh via Homebrew
brew install gh

# Stow will symlink config.yml to ~/.config/gh/config.yml
./dotfiles.sh reinstall

# Authenticate with GitHub
gh auth login

# Verify configuration
gh config list
```

## Integration Points

### Git Integration
- MUST work seamlessly with git repositories
- SHOULD use same protocol (SSH) as git
- MUST respect .gitignore and git configuration
- MAY use git remotes for operations

### Editor Integration
- MUST use nvim from dotfiles configuration
- SHOULD inherit nvim keybindings and plugins
- MUST work for editing PR/issue descriptions

### SSH Integration
- MUST use SSH keys from dotfiles
- SHOULD work with gpg-agent if configured for SSH
- MUST authenticate via SSH to GitHub

### Dotfiles Integration
- MUST be managed via GNU Stow like other packages
- MUST be listed in packages.config with XDG path
- SHOULD have version requirement in versions.config
- MUST validate installation in dotfiles.sh status

## Key Concepts

### GitHub CLI Workflows

**Pull Requests:**
```bash
gh pr create        # Create PR from current branch
gh pr list          # List PRs (alias: pl)
gh pr view          # View PR details (alias: pv)
gh pr checkout 123  # Check out PR #123 (alias: co)
gh pr review        # Review a PR
gh pr merge         # Merge a PR
```

**Issues:**
```bash
gh issue create     # Create new issue
gh issue list       # List issues (alias: il)
gh issue view       # View issue details
gh issue close      # Close issue
```

**Repositories:**
```bash
gh repo view        # View repo details (alias: rv)
gh repo clone       # Clone repo (alias: rc)
gh repo fork        # Fork a repo
gh status           # Show status across repos (alias: st)
```

**Releases:**
```bash
gh release create   # Create a release
gh release list     # List releases
gh release view     # View release details
```

## Customization

### Local Overrides
To customize gh configuration after installation:
```bash
# Edit the stowed config directly
nvim ~/.config/gh/config.yml

# Changes will be reflected immediately
gh config list
```

### Adding Custom Aliases
Add to `aliases` section in config.yml:
```yaml
aliases:
    my-alias: "command args"
```

### Changing Default Editor
Modify `editor` field:
```yaml
editor: code --wait  # Use VS Code instead of nvim
```

## Validation

### Configuration Validation
```bash
# Verify config loads without errors
gh config list

# Check specific setting
gh config get editor

# Validate aliases work
gh st  # Should run 'gh status'
```

### Authentication Testing
```bash
# Check authentication status
gh auth status

# Test API access
gh api user

# Verify SSH access
gh auth refresh
```

## Troubleshooting

### Config Not Loading
- MUST verify config.yml is at `~/.config/gh/config.yml`
- MUST check file permissions are readable
- SHOULD run `gh config list` to see active configuration

### Authentication Issues
- MUST verify GitHub authentication: `gh auth status`
- SHOULD re-authenticate if needed: `gh auth login`
- MAY need to refresh token: `gh auth refresh`

### SSH Protocol Issues
- MUST verify SSH keys are added to GitHub
- SHOULD check SSH agent is running with keys loaded
- MAY need to test SSH: `ssh -T git@github.com`

## Security Considerations

### Authentication
- MUST use OAuth tokens securely
- SHOULD store tokens in system keychain
- MUST NOT commit tokens to repositories
- MAY configure token scopes as needed

### SSH Keys
- MUST use SSH protocol for git operations
- SHOULD leverage existing SSH keys from dotfiles
- MUST ensure keys are encrypted and in SSH agent

### API Access
- MUST respect GitHub API rate limits
- SHOULD cache responses when appropriate
- MUST NOT expose tokens in logs or output

## Version Requirements
- MUST have gh >= 2.40.0 for latest features
- SHOULD have delta >= 0.16 for optimal output
- MUST have nvim >= 0.9 (from dotfiles)

## References
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub CLI Configuration](https://cli.github.com/manual/gh_config)
- [GitHub CLI Aliases](https://cli.github.com/manual/gh_alias)
