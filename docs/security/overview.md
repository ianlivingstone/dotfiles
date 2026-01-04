# Security Overview

## Security Design Principles

### Security-First Design
- All features designed with security in mind from the start
- Never compromise security for convenience
- Security validations built into core workflows
- Automated security checks in CI/CD

### Defense in Depth
- Multiple layers of security controls
- Permission management at filesystem level
- Input validation at application level
- Credential isolation at configuration level
- Regular security audits

### Principle of Least Privilege
- Tools granted minimum permissions needed
- Machine-specific data separated from repository
- SSH key authentication only (no passwords)
- GPG signing required for commits

## Threat Model for Dotfiles

### What We Protect Against

**Credential exposure:**
- Accidental commit of SSH/GPG private keys
- Exposure of personal emails, names, API keys
- Leakage of machine-specific hostnames or IPs
- Credentials in shell history or logs

**Command injection:**
- Malicious input exploiting shell scripts
- Unquoted variables leading to code execution
- Eval with user-controlled data
- Path traversal attacks

**Unauthorized access:**
- Improper file permissions on sensitive files
- World-readable SSH keys or GPG keys
- Weak or missing authentication
- Session hijacking

**Supply chain attacks:**
- Malicious scripts downloaded via HTTP
- Unverified checksums on downloads
- Compromised package repositories
- Man-in-the-middle attacks

### What We Don't Protect Against

**Physical access:**
- Attacker with physical access to machine
- Assumes machine itself is secure

**Compromised dependencies:**
- Security of Homebrew, Git, etc. is their responsibility
- We verify versions but not package integrity

**User error:**
- User manually committing credentials
- User disabling security features
- User ignoring security warnings

## Security Architecture Overview

### Layered Configuration

**Repository (public/shared):**
- Tool configurations (Git aliases, SSH patterns)
- Security best practices (disabled password auth)
- No personal data whatsoever

**Machine-specific (private):**
- Personal identities (Git user.name, user.email)
- SSH key references (IdentityFile paths)
- GPG signing keys
- Machine hostnames

**Separation mechanism:**
- Native tool includes (Git [include], SSH Include)
- XDG directories (~/.config/)
- .gitignore coverage
- Installation-time generation

### Permission Model

**Sensitive files (600):**
- SSH private keys (~/.ssh/id_*)
- Machine configs with credentials

**Sensitive directories (700):**
- SSH directory (~/.ssh/)
- GPG directory (~/.gnupg/)
- SSH sockets (~/.ssh/sockets/)

**Shared configs (644):**
- Git configuration (~/.gitconfig)
- Shell configuration (~/.zshrc)
- Tool configurations

**Executables (755):**
- Shell scripts
- Utility binaries

### Network Security

**Enforce HTTPS:**
- Secure curl pattern: `--proto '=https' --tlsv1.2`
- No HTTP URLs in scripts or configs
- Checksum validation for downloads

**SSH Security:**
- Key-based authentication only
- Disabled password authentication
- Connection multiplexing for performance
- Control sockets in secure directory

## Common Security Pitfalls

### Credential Leakage
**Problem:** Personal data committed to git
**Solution:** Machine-specific configs in ~/.config/, never in repo

### Command Injection
**Problem:** Unquoted variables enable code execution
**Solution:** Always quote variables, validate input

### Permission Issues
**Problem:** SSH keys world-readable
**Solution:** Automated permission validation on startup

### Insecure Downloads
**Problem:** Scripts downloaded via HTTP
**Solution:** Enforce HTTPS with modern TLS

## Security Validation Workflow

### At Installation
1. Check dependencies exist
2. Validate file permissions
3. Generate machine configs securely
4. Verify .gitignore coverage

### At Shell Startup
1. Validate SSH key permissions
2. Check GPG directory permissions
3. Verify machine configs exist
4. Warn on security issues

### At Commit
1. Verify GPG signing enabled
2. Check no credentials staged
3. Validate commit signature
4. Scan for sensitive patterns

### Periodically
1. Review .gitignore coverage
2. Audit shell scripts for security issues
3. Check for accidentally committed credentials
4. Update security patterns as needed

## Security Testing

### Automated Tests
- Input validation with malicious patterns
- Permission validation on sensitive files
- Credential isolation verification
- .gitignore coverage checks

### Manual Reviews
- Code review for security issues
- Shell script validation with shellcheck
- Permission audit with ls -la
- Git history scan for credentials

## Known Security Issues

For current security issues and detailed fixes, see `shell/AGENTS.md`:
- Command injection vulnerabilities (fixed)
- Permission validation issues (addressed)
- Safe mode requirements for destructive operations

## Security Incident Response

### If Credentials Committed

1. **Immediate action:**
   - Revoke compromised credentials
   - Generate new SSH/GPG keys
   - Update machine.config with new credentials

2. **Remove from history:**
   ```bash
   # Use BFG Repo Cleaner or git filter-branch
   # WARNING: Rewrites history
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch path/to/file" \
     --prune-empty --tag-name-filter cat -- --all
   ```

3. **Prevention:**
   - Verify .gitignore coverage
   - Add pre-commit hook to scan for credentials
   - Review what went wrong

### If Vulnerability Discovered

1. **Assess impact:**
   - What systems affected?
   - What data exposed?
   - Who needs to know?

2. **Fix immediately:**
   - Patch vulnerability
   - Test fix thoroughly
   - Deploy to all machines

3. **Document:**
   - Add to known issues in shell/AGENTS.md
   - Update security patterns
   - Notify affected users

## Security Contacts

For security issues:
- Review docs/security/patterns.md first
- Check shell/AGENTS.md for known issues
- File issue in repository if new vulnerability

## Cross-References

- docs/security/patterns.md (Implementation details)
- docs/security/multi-machine.md (Machine isolation)
- docs/security/auditing.md (Validation process)
- shell/AGENTS.md (Known security issues)
