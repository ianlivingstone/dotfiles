# Multi-Machine Configuration Architecture

## Design Rationale

This dotfiles system separates shared configuration from machine-specific personal data to enable:

### MUST support different identities per machine
- Different Git name/email per machine (work email vs personal email)
- Different SSH keys per machine (work keys vs personal keys)
- Different GPG signing keys per machine
- Different hostnames and machine-specific settings

### MUST prevent personal data from entering git repository
- Personal identities (names, emails) stay on local machine only
- SSH/GPG key references stay on local machine only
- Hostname and machine-specific paths never committed
- Only shared configuration patterns committed to git

### MUST maintain identical tool configurations across machines
- Git aliases, settings, and hooks identical everywhere
- SSH security settings and patterns identical everywhere
- Shell configuration and functions identical everywhere
- Only personal identity differs between machines

## Layered Configuration Implementation

**Architecture pattern:** Base configurations use native tool includes to layer machine-specific configs.

### Git Configuration Layering

**Base configuration (in repository):**
```bash
# git/.gitconfig
[include]
    path = ~/.config/git/machine.config

[core]
    # Shared settings for all machines
    editor = nvim
    pager = delta

[alias]
    # Shared aliases for all machines
    st = status
    co = checkout
```

**Machine-specific configuration (not in repository):**
```bash
# ~/.config/git/machine.config
[user]
    name = Ian Livingstone
    email = work@company.com
    signingkey = ABCD1234WORKKEY

[commit]
    gpgsign = true
```

**MUST follow these rules for Git layering:**
- MUST use `[include] path = ~/.config/git/machine.config` in base .gitconfig
- MUST generate machine.config during installation with user input
- MUST store machine.config in `~/.config/git/` (XDG directory)
- NEVER commit machine.config to repository
- MUST validate machine.config exists before Git operations requiring identity

### SSH Configuration Layering

**Base configuration (in repository):**
```bash
# ssh/.ssh/config
Include ~/.config/ssh/machine.config

# Shared settings for all machines
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 10
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
```

**Machine-specific configuration (not in repository):**
```bash
# ~/.config/ssh/machine.config
Host github.com
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes

Host personal-server
    HostName 192.168.1.100
    User ian
    IdentityFile ~/.ssh/id_ed25519_personal
```

**MUST follow these rules for SSH layering:**
- MUST use `Include ~/.config/ssh/machine.config` at top of base config
- MUST generate machine.config during installation with key selection
- MUST store machine.config in `~/.config/ssh/` (XDG directory)
- NEVER commit machine.config or private keys to repository
- MUST validate SSH key permissions (600 for private keys, 644 for public keys)

## XDG Directory Usage

### MUST use XDG Base Directory specification for machine configs

```bash
# Get XDG config directory (with fallback)
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Machine-specific config locations
GIT_MACHINE_CONFIG="$XDG_CONFIG_HOME/git/machine.config"
SSH_MACHINE_CONFIG="$XDG_CONFIG_HOME/ssh/machine.config"
```

### MUST respect existing XDG environment variables
- Check `$XDG_CONFIG_HOME` before defaulting to `~/.config`
- Check `$XDG_DATA_HOME` before defaulting to `~/.local/share`
- Check `$XDG_CACHE_HOME` before defaulting to `~/.cache`
- NEVER override user's existing XDG settings

### MUST create XDG directories with proper permissions
```bash
# Create directory structure securely
mkdir -p "$XDG_CONFIG_HOME/git"
chmod 755 "$XDG_CONFIG_HOME/git"

mkdir -p "$XDG_CONFIG_HOME/ssh"
chmod 700 "$XDG_CONFIG_HOME/ssh"  # More restrictive for SSH
```

## Installation Workflow for Machine-Specific Configs

The `./dotfiles.sh install` command handles machine-specific configuration:

### Step 1: Prompt for Git identity
```bash
# Interactive prompts (uses /dev/tty for stdin compatibility)
read -p "Enter your Git name: " git_name < /dev/tty
read -p "Enter your Git email: " git_email < /dev/tty
```

### Step 2: Scan for SSH keys
```bash
# Find available SSH keys
available_keys=($(find ~/.ssh -name "id_*" -not -name "*.pub" 2>/dev/null))

# Present selection menu
echo "Available SSH keys:"
for i in "${!available_keys[@]}"; do
    echo "$((i+1))) ${available_keys[$i]}"
done
read -p "Select SSH key: " selection < /dev/tty
```

### Step 3: Scan for GPG keys
```bash
# Find available GPG keys
gpg --list-secret-keys --keyid-format LONG

# Prompt for selection
read -p "Enter GPG key ID for signing: " gpg_key < /dev/tty
```

### Step 4: Generate machine configs
```bash
# Generate Git machine config
cat > "$XDG_CONFIG_HOME/git/machine.config" <<EOF
[user]
    name = $git_name
    email = $git_email
    signingkey = $gpg_key

[commit]
    gpgsign = true
EOF
chmod 644 "$XDG_CONFIG_HOME/git/machine.config"

# Generate SSH machine config
cat > "$XDG_CONFIG_HOME/ssh/machine.config" <<EOF
Host github.com
    IdentityFile $selected_ssh_key
    IdentitiesOnly yes
EOF
chmod 600 "$XDG_CONFIG_HOME/ssh/machine.config"
```

**MUST follow these rules during installation:**
- MUST read from `/dev/tty` for interactive prompts (stdin may be redirected)
- MUST validate user input before writing configs
- MUST set correct permissions on generated configs
- MUST verify configs don't already exist or prompt for overwrite
- SHOULD reuse existing configs if found during reinstallation

## Verification and Validation

### MUST validate machine configs before operations

```bash
# Verify Git identity is configured
if ! git config user.email &>/dev/null; then
    echo "Error: Git identity not configured"
    echo "Run: ./dotfiles.sh install"
    return 1
fi

# Verify SSH key exists and has correct permissions
ssh_key=$(grep "IdentityFile" ~/.config/ssh/machine.config | awk '{print $2}')
if [[ ! -f "$ssh_key" ]]; then
    echo "Error: SSH key not found: $ssh_key"
    return 1
fi
if [[ "$(stat -f %A "$ssh_key")" != "600" ]]; then
    echo "Warning: SSH key has incorrect permissions"
    chmod 600 "$ssh_key"
fi
```

### MUST ensure machine configs never enter repository

```bash
# Verify .gitignore includes machine configs
# .gitignore should contain:
.config/git/machine.config
.config/ssh/machine.config
```

### SHOULD validate during shell startup (automatic check)
- Check that machine.config files exist
- Warn if files have incorrect permissions
- Suggest running `./dotfiles.sh install` if missing

## Testing Multi-Machine Configuration

### Test on new machine
```bash
# 1. Clone repository
git clone https://github.com/user/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 2. Run installation (should prompt for machine-specific data)
./dotfiles.sh install

# 3. Verify machine configs created
ls -la ~/.config/git/machine.config  # Should exist
ls -la ~/.config/ssh/machine.config  # Should exist

# 4. Verify Git identity
git config user.name   # Should show your name
git config user.email  # Should show your email

# 5. Verify machine configs not tracked by git
git status  # Should not show machine.config files
```

### Test clean reinstallation
```bash
# Reinstall should reuse existing machine configs
./dotfiles.sh reinstall

# Should not prompt for Git identity again
# Should reuse existing ~/.config/git/machine.config
```

## Security Considerations for Multi-Machine Setup

### MUST protect machine-specific configs
- Set 600 permissions on configs with sensitive data (SSH config)
- Set 644 permissions on configs without secrets (Git config)
- Verify configs not world-readable: `ls -la ~/.config/*/machine.config`

### MUST prevent credential leakage
- Never echo or log user input during installation
- Clear sensitive variables after use: `unset git_email gpg_key`
- Avoid storing credentials in shell history

### MUST validate before operations requiring identity
- Check Git identity exists before commits
- Check SSH key exists before connections
- Check GPG key exists before signing

## Cross-References

- docs/security/patterns.md (Security implementation)
- docs/reference/dotfiles-commands.md (install command)
- git/AGENTS.md, ssh/AGENTS.md (Implementation details)
