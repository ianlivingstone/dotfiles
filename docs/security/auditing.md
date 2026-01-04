# Security Auditing

## Security Audit Process

### Regular Security Audits

Perform security audits:
- **Weekly:** Quick permission and credential checks
- **Monthly:** Comprehensive security review
- **Before major changes:** Full security assessment
- **After incidents:** Root cause analysis and remediation

### Quick Security Audit (Weekly)

```bash
# 1. Check for credentials in repository
git status  # Should not show machine.config files
git log --all --full-history -- '*.config' | grep machine  # Should be empty

# 2. Verify file permissions
ls -la ~/.ssh/  # Keys should be 600, directory 700
ls -la ~/.gnupg/  # Should be 700
ls -la ~/.config/git/  # machine.config should be 644
ls -la ~/.config/ssh/  # machine.config should be 600

# 3. Check .gitignore coverage
git check-ignore ~/.config/git/machine.config  # Should match
git check-ignore ~/.config/ssh/machine.config  # Should match

# 4. Validate shell startup security
source shell/security.sh
validate_key_security  # Should pass or warn
```

### Comprehensive Security Audit (Monthly)

```bash
# 1. Credential scan
grep -r "password\|api_key\|token\|secret" . --exclude-dir=.git
grep -r "@.*\.com" . --exclude-dir=.git  # Check for emails

# 2. Permission audit
find ~/.ssh -type f -exec ls -la {} \;  # Review all SSH files
find ~/.gnupg -type f -exec ls -la {} \;  # Review all GPG files

# 3. Shell script security review
shellcheck shell/*.sh
shellcheck dotfiles.sh
# Review output for security issues

# 4. Input validation audit
grep -r "read.*<" . --exclude-dir=.git  # Find user input
# Review each for proper validation

# 5. Network security audit
grep -r "curl\|wget" . --exclude-dir=.git  # Find network operations
# Verify all use HTTPS with TLS 1.2+

# 6. Git history scan
git log --all --oneline | grep -i "password\|key\|secret"
# Investigate any suspicious commits
```

## Automated Security Checks

### Pre-commit Security Validation

```bash
# In .git/hooks/pre-commit
#!/usr/bin/env bash

# Check for credentials
if git diff --cached --name-only | grep -q "machine\.config"; then
    echo "Error: Attempting to commit machine.config"
    exit 1
fi

# Check for sensitive patterns
if git diff --cached | grep -qE "(api_key|password|secret)"; then
    echo "Warning: Possible credential in commit"
    echo "Review carefully before committing"
fi

# Check file permissions
if ! source shell/security.sh && validate_key_security; then
    echo "Warning: Security validation failed"
fi
```

### dotfiles.sh status Security Checks

The `./dotfiles.sh status` command includes security validation:

```bash
# Permission validation
validate_permissions() {
    local issues=0

    # SSH directory
    if [[ -d ~/.ssh && "$(stat -f %A ~/.ssh)" != "700" ]]; then
        echo "⚠️  SSH directory has wrong permissions"
        ((issues++))
    fi

    # SSH keys
    for key in ~/.ssh/id_*; do
        [[ -f "$key" && ! "$key" =~ \.pub$ ]] || continue
        if [[ "$(stat -f %A "$key")" != "600" ]]; then
            echo "⚠️  SSH key $key has wrong permissions"
            ((issues++))
        fi
    done

    # GPG directory
    if [[ -d ~/.gnupg && "$(stat -f %A ~/.gnupg)" != "700" ]]; then
        echo "⚠️  GPG directory has wrong permissions"
        ((issues++))
    fi

    return $issues
}
```

## Manual Security Review Checklist

### Code Review Security Checklist

When reviewing code changes:

**Credential Security:**
- [ ] No credentials, API keys, or tokens in code
- [ ] No personal data (emails, names) in committed files
- [ ] No SSH/GPG private keys in repository
- [ ] Machine configs use XDG directories and are in .gitignore

**Input Validation:**
- [ ] All user input validated before use in commands
- [ ] All variables properly quoted in shell commands
- [ ] No use of `eval` with user-controlled data
- [ ] No direct interpolation of user input into SQL/commands

**Permissions:**
- [ ] Sensitive directories have 700 permissions
- [ ] Private keys have 600 permissions
- [ ] Config files without secrets have 644 permissions
- [ ] Permission validation runs on shell startup

**Network Security:**
- [ ] All curl commands use `--proto '=https' --tlsv1.2`
- [ ] Downloaded files have checksum verification where applicable
- [ ] No HTTP URLs in scripts or configs
- [ ] SSH configs disable password authentication

**Audit Trail:**
- [ ] Sensitive operations logged (file modifications, permission changes)
- [ ] Git commits properly signed (GPG)
- [ ] Changes to security-critical files reviewed

### Shell Script Security Review

```bash
# Run shellcheck on all scripts
shellcheck shell/*.sh dotfiles.sh

# Check for common issues:
# - Unquoted variables
# - Missing input validation
# - Unsafe command patterns
# - Credential handling
```

### Permission Audit Commands

```bash
# Find files with insecure permissions
find ~/.ssh -type f ! -perm 600 ! -name "*.pub"
find ~/.gnupg -type f ! -perm 600

# Find world-readable sensitive files
find ~/.ssh ~/.gnupg -perm -004

# Check directory permissions
find ~/.ssh ~/.gnupg -type d ! -perm 700
```

## Known Security Issues

For current security issues and detailed fixes, see `shell/AGENTS.md`:

### Fixed Issues

**Command injection in dotfiles.sh (Fixed):**
- Issue: Unquoted variables allowed code execution
- Fix: Quote all variables, validate input
- Verification: Test with malicious input

**Permission validation issues (Fixed):**
- Issue: Permissions not checked consistently
- Fix: Automated validation on startup
- Verification: Run ./dotfiles.sh status

### Open Issues

See `shell/AGENTS.md` for current open issues and remediation plans.

## Security Testing Commands

### Test credential isolation
```bash
# Verify no credentials in repository
git status
git log --all --full-history -- '*.config' | grep machine

# Check .gitignore coverage
git check-ignore ~/.config/git/machine.config
git check-ignore ~/.config/ssh/machine.config
```

### Test permission validation
```bash
# Test SSH key permissions
ls -la ~/.ssh/  # Keys should be 600, directory 700

# Test GPG permissions
ls -la ~/.gnupg/  # Should be 700

# Test validation function
source shell/security.sh
validate_key_security  # Should pass or warn
```

### Test input validation
```bash
# Test with malicious input
echo "'; rm -rf /'" | ./dotfiles.sh install  # Should reject

# Test with path traversal
./dotfiles.sh status "../../../etc/passwd"  # Should validate

# Test command injection
bash -c "ls ; rm -rf /"  # Should be blocked by permissions
```

### Test network security
```bash
# Verify HTTPS enforcement
grep -r "curl.*http:" . --exclude-dir=.git  # Should find none
grep -r "wget.*http:" . --exclude-dir=.git  # Should find none

# Check for secure curl pattern
grep -r "SECURE_CURL" . --exclude-dir=.git  # Should find usage
```

## Periodic Audit Guidelines

### Weekly Audit (5 minutes)
1. Run `./dotfiles.sh status`
2. Check for security warnings
3. Verify no credentials in `git status`
4. Quick permission check on ~/.ssh and ~/.gnupg

### Monthly Audit (30 minutes)
1. Full credential scan
2. Permission audit all sensitive files
3. Shell script security review with shellcheck
4. Input validation review
5. Network security audit
6. Review git history for issues

### Quarterly Audit (2 hours)
1. Comprehensive security assessment
2. Review all security patterns
3. Update security documentation
4. Test security incident response
5. Review and update .gitignore
6. Audit all shell scripts
7. Check for new vulnerabilities

## Security Audit Report Template

```markdown
# Security Audit Report

**Date:** YYYY-MM-DD
**Auditor:** Name
**Scope:** Full security audit

## Summary
- Issues found: X
- Critical: X
- High: X
- Medium: X
- Low: X

## Findings

### Critical
1. [Issue description]
   - Impact: [What could happen]
   - Remediation: [How to fix]
   - Timeline: [When to fix by]

### High
...

### Medium
...

### Low
...

## Recommendations
1. [Recommendation]
2. [Recommendation]

## Follow-up
- Next audit: YYYY-MM-DD
- Open issues to track: [Links]
```

## Cross-References

- docs/security/patterns.md (Patterns to check)
- docs/security/overview.md (Threat model)
- shell/AGENTS.md (Known shell security issues)
- docs/development/testing-debugging.md (Testing patterns)
