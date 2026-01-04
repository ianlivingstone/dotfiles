# Version Management

## versions.config Architecture

The dotfiles system uses a centralized `versions.config` file to specify minimum required versions for all tools.

### File Format
```bash
# versions.config
# Format: TOOL=VERSION

# Core tools
GIT_VERSION=2.40
DOCKER_VERSION=28.0
NVIM_VERSION=0.9
TMUX_VERSION=3.2

# Language runtimes
NODE_VERSION=v24.1.0
GO_VERSION=go1.24.1
RUST_VERSION=1.70
```

### Version Validation

The `./dotfiles.sh status` command validates installed versions against requirements:

```bash
# Read version from config
required_version=$(grep "^${TOOL}_VERSION=" versions.config | cut -d'=' -f2)

# Get installed version
installed_version=$(tool --version | extract_version)

# Compare versions
if version_less_than "$installed_version" "$required_version"; then
    echo "❌ $tool $installed_version (required: $required_version+)"
else
    echo "✅ $tool $installed_version (required: $required_version+)"
fi
```

## How Version Validation Works

### Semantic Versioning Comparison

```bash
# Version comparison function
version_less_than() {
    local v1="$1"
    local v2="$2"

    # Strip leading 'v' or 'go' prefixes
    v1="${v1#v}"
    v1="${v1#go}"
    v2="${v2#v}"
    v2="${v2#go}"

    # Compare major.minor.patch
    [[ "$(printf '%s\n' "$v1" "$v2" | sort -V | head -n1)" != "$v2" ]]
}
```

### Tool-Specific Version Extraction

```bash
# Git version
git --version  # git version 2.45.0
# Extract: 2.45.0

# Docker version
docker --version  # Docker version 28.1.0, build abc123
# Extract: 28.1.0

# Node version
node --version  # v24.1.0
# Extract: v24.1.0 (keep 'v' prefix)

# Go version
go version  # go version go1.24.1 darwin/amd64
# Extract: go1.24.1
```

## Adding New Version Requirements

### Step 1: Add to versions.config
```bash
# Add new tool requirement
echo "NEWTOOL_VERSION=1.2.3" >> versions.config
```

### Step 2: Update dotfiles.sh status command
```bash
# In dotfiles.sh check_version_compliance()

# Add version check for new tool
if command -v newtool &> /dev/null; then
    required=$(grep "^NEWTOOL_VERSION=" versions.config | cut -d'=' -f2)
    installed=$(newtool --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

    if version_less_than "$installed" "$required"; then
        echo "❌ newtool $installed (required: $required+)"
        has_errors=1
    else
        echo "✅ newtool $installed (required: $required+)"
    fi
fi
```

### Step 3: Document in README.md
```markdown
## Requirements

- newtool 1.2.3+ - Install: `brew install newtool`
```

## Update Command Implementation

The `./dotfiles.sh update` command updates tools to match versions.config.

### Currently Supported: Node.js and Go

```bash
# update_versions() in dotfiles.sh

# Node.js via NVM
if command -v nvm &> /dev/null; then
    node_version=$(grep "^NODE_VERSION=" versions.config | cut -d'=' -f2)
    nvm install "$node_version"
    nvm use "$node_version"
    nvm alias default "$node_version"
fi

# Go via GVM
if command -v gvm &> /dev/null; then
    go_version=$(grep "^GO_VERSION=" versions.config | cut -d'=' -f2)
    gvm install "$go_version"
    gvm use "$go_version" --default
fi
```

### Adding Update Support for New Tools

To add update support for a new tool:

1. **Add version manager check**
```bash
if ! command -v tool-version-manager &> /dev/null; then
    echo "⚠️  tool-version-manager not found"
    echo "Install: brew install tool-version-manager"
    return 1
fi
```

2. **Read target version**
```bash
target_version=$(grep "^TOOL_VERSION=" versions.config | cut -d'=' -f2)
```

3. **Install via version manager**
```bash
tool-version-manager install "$target_version"
tool-version-manager use "$target_version" --default
```

4. **Validate installation**
```bash
if command -v tool &> /dev/null; then
    installed=$(tool --version)
    echo "✅ $tool $installed installed"
else
    echo "❌ $tool installation failed"
    return 1
fi
```

## Version Manager Integration

### NVM (Node Version Manager)

```bash
# Installation
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Shell integration (added by dotfiles)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Usage
nvm install v24.1.0
nvm use v24.1.0
nvm alias default v24.1.0
```

### GVM (Go Version Manager)

```bash
# Installation
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

# Shell integration (added by dotfiles)
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# Usage
gvm install go1.24.1
gvm use go1.24.1 --default
```

### Rustup (Rust Version Manager)

```bash
# Installation
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Shell integration (added by dotfiles)
source "$HOME/.cargo/env"

# Usage
rustup install 1.70
rustup default 1.70
```

## Troubleshooting Version Issues

### Version mismatch detected
```bash
# Problem: ./dotfiles.sh status shows version too old
❌ nvim 0.8.3 (required: 0.9+)

# Solution: Update the tool
brew upgrade nvim
# Then verify
./dotfiles.sh status
```

### Update command fails
```bash
# Problem: ./dotfiles.sh update fails

# Check version manager installed
command -v nvm  # Should exist
command -v gvm  # Should exist

# Install missing version manager
# See shell/AGENTS.md for installation instructions
```

### Version manager not found
```bash
# Problem: nvm/gvm commands not available

# Check shell integration
echo $NVM_DIR  # Should show ~/.nvm
which gvm      # Should show path

# Reload shell configuration
source ~/.zshrc
```

## Cross-References

- docs/reference/dotfiles-commands.md (update command)
- shell/AGENTS.md (Version manager integration)
- versions.config (Actual version requirements)
