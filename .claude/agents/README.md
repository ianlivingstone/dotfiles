# Dotfiles Repository-Specific Agents

This directory contains agents specialized for working on **THIS dotfiles repository only**.

**IMPORTANT DISTINCTION**:
- **`.claude/agents/`** = Repository-specific agents (THIS dotfiles repo only)
- **`claude-code/agents/`** = Generic agents (global harness, could be used anywhere)

## Available Repository-Specific Agents

### product-manager
**Purpose**: Oversees developer and user experience for dotfiles features. Ensures install/reinstall/update/security integration.

**Use When**:
- Planning to add new functionality to dotfiles
- Reviewing feature integration with dotfiles workflows
- Checking if changes will break dotfiles workflows
- Validating install/reinstall/update support
- Ensuring proper documentation

**Example Usage**:
```
> Plan feature: add zellij configuration
> Review UX: does this break existing workflows?
> Check integration: new shell function
> Will this work with install/reinstall/update?
```

**Key Features**:
- Creates feature integration checklists for dotfiles
- Validates all four workflows (install/reinstall/update/security)
- Ensures documentation matches implementation
- Delegates to specialized agents
- Thinks holistically about dotfiles user experience

**Trigger Phrases**:
- "plan feature", "add functionality"
- "review UX", "check integration"
- "will this break", "does this work with"

---

### architecture-assistant
**Purpose**: Expert in dotfiles code architecture and design decisions. Helps with GNU Stow packages, shell modules, and configuration layering.

**Use When**:
- Designing new GNU Stow packages for dotfiles
- Organizing shell modules
- Planning configuration layering (shared vs machine-specific)
- Making architectural choices for dotfiles system
- Structuring dotfiles code

**Example Usage**:
```
> How should I structure a new tool package?
> Design shell module organization
> Architecture decision: how to layer configs?
> Add package for alacritty
```

**Key Features**:
- Understands GNU Stow patterns used in this repo
- Designs configuration layering for dotfiles
- Plans shell module organization
- Makes architectural trade-offs for dotfiles system
- Ensures security and performance

**Trigger Phrases**:
- "architecture decision", "how should I structure"
- "design this feature", "add package"
- "organize shell code", "configuration layering"

---

### shell-validator
**Purpose**: Validates bash and zsh scripts in dotfiles for errors, security issues, and project standards.

**Use When**:
- Reviewing shell scripts in dotfiles before committing
- Checking dotfiles scripts for security vulnerabilities
- Validating shellcheck compliance
- Ensuring dotfiles project-specific patterns
- Finding command injection risks in dotfiles scripts

**Example Usage**:
```
> Validate shell: dotfiles.sh
> Check bash script for security issues
> Review script: shell/new-module.sh
> Run shellcheck on this file
```

**Key Features**:
- Runs shellcheck analysis
- Detects security vulnerabilities in dotfiles scripts
- Validates variable quoting
- Checks command injection risks
- Ensures dotfiles project pattern compliance

**Trigger Phrases**:
- "validate shell", "check bash"
- "shellcheck", "review script"
- "security issues" + shell file

---

### security-auditor
**Purpose**: Audits dotfiles repository for security vulnerabilities and compliance.

**Use When**:
- Before committing changes to dotfiles
- Checking for hardcoded credentials in dotfiles
- Validating file permissions
- Reviewing .gitignore coverage
- Scanning for security issues in dotfiles
- After adding new features to dotfiles

**Example Usage**:
```
> Security audit before commit
> Check for hardcoded credentials
> Validate file permissions
> Scan for vulnerabilities
> Audit .gitignore coverage
```

**Key Features**:
- Scans for hardcoded credentials in dotfiles repo
- Validates file permissions (600/700) for dotfiles configs
- Checks .gitignore coverage for machine-specific files
- Detects command injection in dotfiles scripts
- Validates GPG signing enabled for commits

**Trigger Phrases**:
- "security audit", "check vulnerabilities"
- "credential scan", "check permissions"
- "gitignore review"

---

### documentation-reviewer
**Purpose**: Reviews and maintains documentation quality for dotfiles repository, focusing on Agent Rules compliance and accuracy.

**Use When**:
- Reviewing AGENTS.md files for compliance
- Checking documentation accuracy after code changes
- Validating links in documentation
- Auditing docs before major releases
- Finding outdated documentation
- Ensuring Agent Rules specification compliance

**Example Usage**:
```
> Review documentation
> Check AGENTS.md for compliance
> Audit docs for broken links
> Validate documentation accuracy
> Check for outdated content
```

**Key Features**:
- Validates Agent Rules compliance (RFC 2119 keywords, imperative statements)
- Checks for broken links (internal and external)
- Verifies documentation matches current code
- Finds outdated examples and references
- Suggests clarity improvements
- Can auto-fix simple compliance issues

**Trigger Phrases**:
- "review documentation", "check AGENTS.md"
- "audit docs", "validate documentation"
- "check for broken links"

---

## Why Repository-Specific?

These agents are specialized for this dotfiles repository because they:
- Understand GNU Stow package patterns used here
- Know about install/reinstall/update workflows specific to dotfiles.sh
- Validate against dotfiles-specific security requirements
- Understand shell module organization in shell/
- Check machine-specific vs shared configuration patterns
- Know about versions.config and packages.config

They would not be useful in other types of repositories.

## Using These Agents

### Explicit Invocation
```
> Use the product-manager agent to plan this feature
> Have the security-auditor check before I commit
```

### Automatic Delegation
Claude will automatically use these agents when trigger phrases match:
```
> Plan feature: add new tool
  → Triggers product-manager

> Validate shell script
  → Triggers shell-validator

> Security audit
  → Triggers security-auditor
```

## Generic Agents

For generic agent operations (not dotfiles-specific), see:
- `claude-code/agents/README.md` - Generic agents in the global harness
- Currently: harness-architect (helps design any agents, not dotfiles-specific)
