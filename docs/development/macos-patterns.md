# macOS-Specific Development Patterns

## Homebrew Integration

### Check for Homebrew tools
```bash
# ✅ GOOD: Check before using
if ! command -v tool &> /dev/null; then
    echo "Install with: brew install tool"
    return 1
fi

# ❌ BAD: Assume tool exists
tool --version
```

### Cache Homebrew prefix
```bash
# ✅ GOOD: Cache expensive operation
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    HOMEBREW_PREFIX="$(brew --prefix)"
    export HOMEBREW_PREFIX
fi

# ❌ BAD: Call every time (slow)
PATH="$(brew --prefix)/bin:$PATH"
```

### Homebrew-installed tools in PATH
```bash
# Add Homebrew to PATH
if command -v brew &> /dev/null; then
    HOMEBREW_PREFIX="$(brew --prefix)"
    export PATH="$HOMEBREW_PREFIX/bin:$PATH"
    export PATH="$HOMEBREW_PREFIX/sbin:$PATH"
fi
```

## XDG Directory Handling on macOS

### Respect existing XDG variables
```bash
# ✅ GOOD: macOS-compatible XDG paths with fallback
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# ❌ BAD: Override user's settings
XDG_CONFIG_HOME="$HOME/.config"
```

### Create XDG directories
```bash
# ✅ GOOD: Create with proper permissions
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_DATA_HOME"
mkdir -p "$XDG_CACHE_HOME"

# Note: macOS respects standard Unix permissions
chmod 755 "$XDG_CONFIG_HOME"
```

## Security on macOS

### Secure curl pattern
```bash
# ✅ GOOD: Enforced throughout project
SECURE_CURL="curl --proto '=https' --tlsv1.2"
$SECURE_CURL -sSfL https://example.com/script.sh | bash

# ❌ BAD: Insecure (allows HTTP, old TLS)
curl http://example.com/script.sh | bash
```

### File permissions
```bash
# Private keys: Only owner can read/write
chmod 600 ~/.ssh/id_ed25519

# GPG directory: Only owner can access
chmod 700 ~/.gnupg

# SSH sockets directory
mkdir -p ~/.ssh/sockets && chmod 700 ~/.ssh/sockets

# Config files: Owner read/write, others read
chmod 644 ~/.gitconfig
```

### macOS-specific permission checking
```bash
# ✅ GOOD: macOS stat syntax
perm=$(stat -f %A "$file")

# ❌ BAD: Linux stat syntax (fails on macOS)
perm=$(stat -c %a "$file")
```

## macOS Hostname Commands

### Get hostname
```bash
# Short hostname
hostname -s

# Full hostname
hostname -f

# Get/set system hostname
scutil --get HostName
scutil --set HostName "new-hostname"
```

### Computer name vs hostname
```bash
# Computer name (shown in Finder, Sharing preferences)
scutil --get ComputerName
scutil --set ComputerName "My MacBook"

# Local hostname (for Bonjour, .local)
scutil --get LocalHostName
scutil --set LocalHostName "my-macbook"

# Hostname (for network services)
scutil --get HostName
scutil --set HostName "my-macbook.local"
```

## macOS System Preferences

### Check for required tools
```bash
# Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo "Install Xcode Command Line Tools:"
    echo "xcode-select --install"
    return 1
fi
```

### System defaults
```bash
# Set macOS defaults (examples)
# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Disable press-and-hold for keys (enable key repeat)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Restart affected apps
killall Finder
```

## Path Differences from Linux

### User home directories
```bash
# macOS: /Users/username
# Linux: /home/username

# ✅ GOOD: Use $HOME (portable)
config_dir="$HOME/.config"

# ❌ BAD: Hardcode (not portable)
config_dir="/Users/ian/.config"
```

### Temporary directories
```bash
# macOS: /var/folders/... (via $TMPDIR)
# Linux: /tmp

# ✅ GOOD: Use $TMPDIR with fallback
temp_dir="${TMPDIR:-/tmp}"

# ❌ BAD: Hardcode /tmp
temp_dir="/tmp"
```

## macOS-Specific Tools

### Using BSD vs GNU tools
```bash
# macOS has BSD versions of Unix tools
# Some have different options than GNU versions

# sed differences
# macOS (BSD): sed -i '' 's/old/new/' file
# Linux (GNU): sed -i 's/old/new/' file

# Portable sed in-place edit:
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/old/new/' file
else
    sed -i 's/old/new/' file
fi
```

### Install GNU tools via Homebrew
```bash
# Install GNU versions with 'g' prefix
brew install coreutils  # gls, gcp, gmv, etc.
brew install gnu-sed    # gsed
brew install grep       # ggrep

# Add to PATH (use GNU tools by default)
export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
export PATH="$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="$HOMEBREW_PREFIX/opt/grep/libexec/gnubin:$PATH"
```

## Clipboard Integration

### pbcopy/pbpaste
```bash
# Copy to clipboard
echo "text" | pbcopy

# Paste from clipboard
pbpaste

# Portable clipboard function
if command -v pbcopy &> /dev/null; then
    alias clip='pbcopy'
elif command -v xclip &> /dev/null; then
    alias clip='xclip -selection clipboard'
fi
```

## Notification Center

### Display notifications
```bash
# Using osascript
osascript -e 'display notification "Message" with title "Title"'

# Using terminal-notifier (brew install terminal-notifier)
terminal-notifier -message "Message" -title "Title"
```

## Differences to Be Aware Of

### Case sensitivity
```bash
# macOS filesystem is case-insensitive by default
# (APFS can be case-sensitive, but rare)

# Be careful with file operations
# On macOS: file.txt and File.txt are the same
# On Linux: file.txt and File.txt are different
```

### Open command
```bash
# macOS: open (opens files/URLs with default app)
open file.pdf
open https://example.com
open -a Safari https://example.com

# Linux: xdg-open (similar functionality)
xdg-open file.pdf
```

### Process management
```bash
# macOS uses launchd instead of systemd
# Services managed differently

# List loaded services
launchctl list

# Load/unload service
launchctl load ~/Library/LaunchAgents/service.plist
launchctl unload ~/Library/LaunchAgents/service.plist
```

## Best Practices

### Detect macOS
```bash
# ✅ GOOD: Check $OSTYPE
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS-specific code
fi

# ✅ ALSO GOOD: Check uname
if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS-specific code
fi
```

### Portable scripting
```bash
# Write portable scripts when possible
# Use $HOME, $TMPDIR, $OSTYPE
# Avoid hardcoded paths
# Check tool availability with command -v
```

## Cross-References

- docs/development/shell-patterns.md (Shell patterns)
- docs/security/patterns.md (Security on macOS)
