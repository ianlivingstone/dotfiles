# Security Patterns for Development

## Credential Handling Rules

### NEVER commit credentials, API keys, or personal data to repository
- No hardcoded passwords, tokens, or API keys in any files
- No personal email addresses, names, or identities in committed code
- No SSH private keys or GPG private keys in repository
- No machine-specific hostnames or IP addresses in committed configs

### MUST use environment variables for sensitive data
```bash
# ✅ GOOD: Reference environment variable
API_KEY="${API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
    echo "Error: API_KEY environment variable not set"
    return 1
fi

# ❌ BAD: Hardcoded credential
API_KEY="sk_live_abc123xyz"
```

### MUST validate that machine.config files are in .gitignore
```bash
# Verify these are in .gitignore:
.config/git/machine.config
.config/ssh/machine.config
~/.ssh/id_*
~/.gnupg/
```

### MUST clear sensitive variables after use
```bash
# After using sensitive data
read -s -p "Enter password: " password
# ... use password ...
unset password  # Clear from memory
```

## Input Validation and Command Injection Prevention

### MUST validate and sanitize all user input before using in commands
```bash
# ✅ GOOD: Validate input before use
read -p "Enter filename: " filename
if [[ ! "$filename" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Error: Invalid filename"
    return 1
fi
# Safe to use now

# ❌ BAD: Direct use of user input
read -p "Enter filename: " filename
rm "$filename"  # Command injection risk!
```

### MUST always quote variables in shell commands
```bash
# ✅ GOOD: Properly quoted
file_path="/path/to/file"
cat "$file_path"

# ❌ BAD: Unquoted (word splitting, glob expansion)
cat $file_path
```

### MUST use arrays for complex commands
```bash
# ✅ GOOD: Array prevents word splitting
cmd=(stow --no --restow --target="$target" "$package")
"${cmd[@]}"

# ❌ BAD: String concatenation (word splitting issues)
cmd="stow --no --restow --target=$target $package"
$cmd
```

### MUST avoid eval and uncontrolled expansion
```bash
# ✅ GOOD: Direct variable assignment
XDG_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

# ❌ BAD: Eval with user input
eval "XDG_CONFIG_DIR=$user_input"  # Command injection!
```

## Permission Management Rules

### MUST set correct permissions on sensitive files and directories

```bash
# Private keys: Only owner can read/write
chmod 600 ~/.ssh/id_ed25519
chmod 600 ~/.gnupg/private-keys-v1.d/*

# Directories with keys: Only owner can access
chmod 700 ~/.ssh
chmod 700 ~/.gnupg
chmod 700 ~/.ssh/sockets

# Configs without secrets: Owner read/write, group/world read
chmod 644 ~/.gitconfig
chmod 644 ~/.zshrc

# Executables: Owner read/write/execute, group/world read/execute
chmod 755 ~/bin/scripts/*
```

### MUST validate permissions during shell startup
```bash
# Automatic validation in shell/security.sh
validate_key_security() {
    local ssh_dir="$HOME/.ssh"
    local gpg_dir="$HOME/.gnupg"

    # Check SSH directory permissions
    if [[ -d "$ssh_dir" ]]; then
        local ssh_perm=$(stat -f %A "$ssh_dir")
        if [[ "$ssh_perm" != "700" ]]; then
            echo "Warning: SSH directory has wrong permissions: $ssh_perm"
            echo "Run: chmod 700 $ssh_dir"
        fi
    fi

    # Check private key permissions
    for key in "$ssh_dir"/id_*; do
        [[ -f "$key" && ! "$key" =~ \.pub$ ]] || continue
        local key_perm=$(stat -f %A "$key")
        if [[ "$key_perm" != "600" ]]; then
            echo "Warning: SSH key $key has wrong permissions: $key_perm"
            echo "Run: chmod 600 $key"
        fi
    done
}
```

### MUST create directories with explicit permissions
```bash
# ✅ GOOD: Explicit permission setting
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets

# ⚠️ OK but not ideal: Relies on umask
mkdir -p ~/.ssh/sockets
```

## Secure Network Operations

### MUST use secure curl pattern throughout project
```bash
# ✅ GOOD: Enforces HTTPS and modern TLS
SECURE_CURL="curl --proto '=https' --tlsv1.2"
$SECURE_CURL -sSfL https://example.com/script.sh | bash

# ❌ BAD: Insecure (allows HTTP, old TLS)
curl http://example.com/script.sh | bash
```

### MUST validate checksums for downloaded files
```bash
# ✅ GOOD: Verify checksum
expected_sha="abc123..."
actual_sha=$(shasum -a 256 downloaded_file | awk '{print $1}')
if [[ "$expected_sha" != "$actual_sha" ]]; then
    echo "Error: Checksum mismatch"
    return 1
fi

# ❌ BAD: No verification
curl -O https://example.com/file
./file
```

### MUST use SSH key authentication, never password authentication
```bash
# In ssh/.ssh/config
Host *
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    PubkeyAuthentication yes
```

## Code Review Security Checklist

Before committing changes, verify:

### Credential Security
- [ ] No credentials, API keys, or tokens in code
- [ ] No personal data (emails, names) in committed files
- [ ] No SSH/GPG private keys in repository
- [ ] Machine configs use XDG directories and are in .gitignore

### Input Validation
- [ ] All user input validated before use in commands
- [ ] All variables properly quoted in shell commands
- [ ] No use of `eval` with user-controlled data
- [ ] No direct interpolation of user input into SQL/commands

### Permissions
- [ ] Sensitive directories have 700 permissions
- [ ] Private keys have 600 permissions
- [ ] Config files without secrets have 644 permissions
- [ ] Permission validation runs on shell startup

### Network Security
- [ ] All curl commands use `--proto '=https' --tlsv1.2`
- [ ] Downloaded files have checksum verification where applicable
- [ ] No HTTP URLs in scripts or configs
- [ ] SSH configs disable password authentication

### Audit Trail
- [ ] Sensitive operations logged (file modifications, permission changes)
- [ ] Git commits properly signed (GPG)
- [ ] Changes to security-critical files reviewed

## Security Testing

### MUST test security-critical changes
```bash
# Test permission validation
./dotfiles.sh status  # Should check file permissions

# Test input validation
echo "'; rm -rf /'" | ./dotfiles.sh install  # Should reject

# Test credential isolation
git status  # Should not show machine.config files

# Test SSH key permissions
ls -la ~/.ssh/  # Keys should be 600, directory should be 700
```

### SHOULD perform security audits periodically
- Review .gitignore to ensure sensitive files excluded
- Check committed history for accidentally committed credentials
- Verify all shell scripts properly quote variables
- Test input validation with malicious input patterns

## Known Security Issues

For current security issues and detailed fixes, see `shell/AGENTS.md`:
- Command injection vulnerabilities in dotfiles.sh (fixed)
- Permission validation issues (addressed)
- Safe mode requirements for destructive operations

## Cross-References

- docs/security/multi-machine.md (Machine-specific configs)
- docs/security/auditing.md (Validation)
- docs/development/shell-patterns.md (Shell implementation)
- shell/AGENTS.md (Known issues and fixes)
