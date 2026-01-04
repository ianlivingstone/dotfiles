# Agent Integration Strategy

This document explains how AI agents (Claude Code sub-agents) use the documentation system.

## Agent Architecture

### Repository-Specific Agents

This repository includes four specialized sub-agents:

**product-manager:** Feature planning and UX oversight
- Ensures features integrate with install/reinstall/update/security
- Reviews impact on user workflows
- Validates documentation completeness
- Delegates to specialized agents

**architecture-assistant:** Code architecture decisions
- Helps with GNU Stow package design
- Advises on shell module organization
- Guides configuration layering
- Suggests structural improvements

**shell-validator:** Bash/zsh script validation
- Runs shellcheck on scripts
- Detects security issues
- Validates project-specific patterns
- Checks code quality standards

**security-auditor:** Security scanning and auditing
- Scans for credentials
- Validates file permissions
- Checks .gitignore coverage
- Reviews for vulnerabilities

See `.claude/agents/README.md` for complete documentation.

## How Agents Use docs/

### Agent Context Loading Pattern

**1. Agent Instructions Specify What to Read**

Each agent's instructions (in `.claude/agents/*.md`) specify which docs/ files to read:

```markdown
# In .claude/agents/shell-validator.md

## What to Read First

MUST read these files before validating shell scripts:
- docs/development/shell-patterns.md (shell best practices)
- docs/security/patterns.md (security requirements)
- docs/quality/code-standards.md (quality standards)
```

**2. Agent Reads Only Task-Specific Docs**

Agents don't load all documentation—only what's needed for their task:

```
shell-validator task: "Validate this shell script"
  ↓
Reads: docs/development/shell-patterns.md (200 lines)
Reads: docs/security/patterns.md (200 lines)
Total: ~400 lines vs 1433 lines (72% reduction)
```

**3. Main Claude Coordinates Agents**

Main Claude Code session:
- Reads CLAUDE.md (200 lines, navigation hub)
- Delegates to appropriate sub-agent
- Sub-agent reads task-specific docs
- Sub-agent returns results

## Agent Delegation Workflow

### Example: Adding a New Feature

```
User: "I want to add Alacritty terminal configuration"
  ↓
Main Claude (reads CLAUDE.md):
  "Adding features → product-manager agent"
  ↓
Invokes: product-manager agent
  ↓
product-manager (reads adding-features.md):
  Creates feature integration checklist:
  1. Installation support? (dependency checking)
  2. Reinstall support? (GNU Stow package)
  3. Update support? (version management)
  4. Security considerations? (no credentials)
  5. Documentation? (README, AGENTS.md)
  6. Testing? (status, full cycle)
  ↓
product-manager delegates to architecture-assistant:
  "How should I structure the Alacritty package?"
  ↓
architecture-assistant (reads package-management.md):
  Designs package structure:
  alacritty/.config/alacritty/alacritty.yml
  ↓
Returns to product-manager:
  Complete integration plan with:
  - Package structure
  - Installation steps
  - Testing checklist
  - Documentation updates
```

## Agent-Specific Documentation Access

### product-manager Agent

**Always reads first:**
```markdown
- docs/development/adding-features.md
  Purpose: Feature integration checklist
  Size: ~200 lines
```

**Reads as needed:**
```markdown
- docs/development/package-management.md (if adding package)
- docs/security/patterns.md (for security requirements)
- docs/reference/dotfiles-commands.md (for workflow understanding)
```

**Delegation pattern:**
```markdown
User request
  ↓
product-manager reads adding-features.md
  ↓
Creates integration checklist
  ↓
Delegates to:
  - architecture-assistant (design)
  - security-auditor (security review)
  - shell-validator (if shell scripts)
  ↓
Validates complete workflow
  ↓
Returns comprehensive plan
```

### architecture-assistant Agent

**Always reads first:**
```markdown
- docs/architecture/overview.md
  Purpose: System architecture understanding
  Size: ~150 lines
```

**Reads as needed:**
```markdown
- docs/development/package-management.md (GNU Stow patterns)
- docs/security/multi-machine.md (config layering)
- docs/development/shell-patterns.md (shell module design)
```

**Usage pattern:**
```markdown
User: "How should I structure this package?"
  ↓
architecture-assistant reads:
  - overview.md (system context)
  - package-management.md (Stow patterns)
  ↓
Provides design recommendations:
  - Package structure
  - Integration points
  - Best practices
  ↓
Documents decision in component AGENTS.md
```

### shell-validator Agent

**Always reads first:**
```markdown
- docs/development/shell-patterns.md
  Purpose: Bash/zsh best practices
  Size: ~200 lines

- docs/security/patterns.md
  Purpose: Security requirements
  Size: ~200 lines
```

**Reads as needed:**
```markdown
- docs/quality/code-standards.md (quality requirements)
```

**Usage pattern:**
```markdown
User: "Validate this shell script"
  ↓
shell-validator reads:
  - shell-patterns.md (best practices)
  - patterns.md (security)
  ↓
Runs shellcheck
  ↓
Checks project-specific patterns
  ↓
Reports issues with fixes
```

### security-auditor Agent

**Always reads first:**
```markdown
- docs/security/patterns.md
  Purpose: Security implementation patterns
  Size: ~200 lines

- docs/security/auditing.md
  Purpose: Audit process
  Size: ~150 lines
```

**Reads as needed:**
```markdown
- docs/security/multi-machine.md (machine config isolation)
- docs/development/shell-patterns.md (shell security)
```

**Usage pattern:**
```markdown
User: "Audit this feature for security"
  ↓
security-auditor reads:
  - patterns.md (what to check)
  - auditing.md (how to audit)
  ↓
Scans for common issues:
  - Credentials
  - Permissions
  - Input validation
  - Network security
  ↓
Reports findings with severity
```

## Context Consumption Comparison

### Before docs/ Structure (Old CLAUDE.md)
```
Main Claude: CLAUDE.md (1433 lines)
Sub-agent: CLAUDE.md (1433 lines, again)
Total: ~2866 lines per agent invocation
Context used: High
```

### After docs/ Structure (New)
```
Main Claude: CLAUDE.md (200 lines)
Sub-agent: Task-specific docs (200-400 lines)
Total: ~400-600 lines per agent invocation
Context saved: 60-78%
```

## Agent Coordination Patterns

### Sequential Delegation
```
User request
  ↓
product-manager (feature planning)
  ↓
architecture-assistant (design)
  ↓
shell-validator (validate scripts)
  ↓
security-auditor (security review)
  ↓
Complete, validated plan
```

### Parallel Delegation
```
User request
  ↓
product-manager
  ├→ architecture-assistant (design)
  ├→ shell-validator (scripts)
  └→ security-auditor (security)
  ↓
Collect results
  ↓
Unified response
```

### Recursive Delegation
```
User: "Add complex feature"
  ↓
product-manager
  ↓
architecture-assistant
  ↓
  Needs security review
  ↓
  security-auditor
  ↓
  Returns to architecture-assistant
  ↓
Returns to product-manager
  ↓
Complete plan
```

## Agent Integration Best Practices

### For Agent Authors

**MUST specify which docs/ files to read:**
```markdown
## What to Read First

MUST read before starting task:
- docs/development/shell-patterns.md
- docs/security/patterns.md
```

**SHOULD minimize context consumption:**
- Only read docs needed for task
- Don't read entire CLAUDE.md
- Reference component AGENTS.md as needed

**MUST document agent capabilities:**
- What tasks agent handles
- What docs agent reads
- When to use this agent

### For Main Claude Code Session

**MUST use CLAUDE.md as navigation hub:**
- Read CLAUDE.md for overview
- Follow decision tree to find relevant docs
- Delegate to appropriate sub-agent

**SHOULD delegate to specialized agents:**
- Use product-manager for feature planning
- Use architecture-assistant for design
- Use shell-validator for shell scripts
- Use security-auditor for security

**MUST coordinate agent results:**
- Collect results from sub-agents
- Synthesize unified response
- Validate completeness

## Testing Agent Integration

### Test Agent Can Access Docs
```
1. Invoke sub-agent
2. Verify agent reads specified docs
3. Check agent provides relevant guidance
4. Confirm context consumption reduced
```

### Test Agent Coordination
```
1. Request requiring multiple agents
2. Verify proper delegation
3. Check results synthesized correctly
4. Confirm no redundant context loading
```

### Test Context Reduction
```
Before: Monitor token usage with old CLAUDE.md
After: Monitor token usage with docs/ structure
Verify: 60-70% reduction achieved
```

## Cross-References

- .claude/agents/README.md (Agent catalog)
- docs/architecture/documentation-strategy.md (Doc organization)
- CLAUDE.md (Navigation hub)
- docs/development/adding-features.md (Feature workflow)
