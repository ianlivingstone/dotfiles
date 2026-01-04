# Documentation Strategy

This file documents how documentation is organized in this repository and how AI agents should access it.

## What Goes Where

### CLAUDE.md (200 lines maximum)
- Quick reference and navigation
- Essential rules that apply everywhere
- Decision tree for finding information
- Links to detailed docs/ for specifics
- Primary entry point for Claude Code

**Purpose:** Fast context loading, navigation hub

**When to update:** Cross-cutting pattern changes affecting multiple components

### docs/ (organized by topic)
- Detailed development guides (100-200 lines per file)
- Comprehensive examples and patterns
- Security guidelines with detailed explanations
- Architecture deep-dives
- Testing strategies

**Purpose:** Detailed guidance for specific tasks

**When to update:** New patterns, detailed workflow changes, comprehensive guidance needed

### ARCHITECTURE.md
- High-level design principles
- Why architectural decisions were made
- Component relationships
- Design philosophy and trade-offs

**Purpose:** Understanding system design rationale

**When to update:** Architectural decisions, high-level design changes

### Component AGENTS.md (e.g., shell/AGENTS.md)
- Component-specific implementation details
- Integration points with other components
- Technical implementation patterns
- Component-specific troubleshooting

**Purpose:** Implementation details for specific components

**When to update:** Component implementation changes, integration point changes

### README.md
- User-facing documentation
- Feature descriptions and benefits
- Installation and quick start
- Usage examples
- Troubleshooting

**Purpose:** User documentation, getting started

**When to update:** User-visible features, installation process, usage patterns

## How Agents Access Documentation

### Main Claude Code Session
1. Loads CLAUDE.md automatically (200 lines, lightweight)
2. CLAUDE.md provides navigation map
3. Claude reads specific docs/ files as needed for task
4. Example: Security task → reads docs/security/patterns.md

### Sub-Agent Sessions
1. Sub-agent receives task from main session
2. Sub-agent's instructions specify which docs/ files to read
3. Sub-agent reads only necessary docs (task-specific)
4. Sub-agent returns results to main session

**Example:** shell-validator agent instructions say "Read docs/development/shell-patterns.md and docs/security/patterns.md"

### When to Read What

**Adding features:**
→ Start with: docs/development/adding-features.md
→ Then: docs/development/package-management.md (if adding package)

**Working with shell scripts:**
→ Read: docs/development/shell-patterns.md
→ And: docs/security/patterns.md

**Security review:**
→ Read: docs/security/patterns.md
→ And: docs/security/auditing.md

**Architecture decisions:**
→ Read: docs/architecture/overview.md
→ Then: Specific area docs as needed

**Command implementation:**
→ Read: docs/reference/dotfiles-commands.md

## Documentation Maintenance Workflow

### Planning Phase
1. Review existing docs to understand current state
2. Reference documentation in the plan (don't duplicate)
3. Note documentation impact in each recommendation
4. Don't update docs yet - wait for plan approval

### Implementation Phase
1. Implement feature code
2. Update technical docs (component AGENTS.md, docs/)
3. Update user-facing docs (README.md)
4. Update architecture docs if needed (ARCHITECTURE.md)
5. Verify all links work
6. Commit docs with code changes

### Update Order Example
```markdown
## Feature Implementation Documentation Updates

1. Implement code
2. Update component/AGENTS.md (implementation details)
3. Update docs/development/ (if new patterns)
4. Update docs/security/ (if security implications)
5. Update CLAUDE.md (if cross-cutting pattern)
6. Update README.md (if user-facing)
7. Update ARCHITECTURE.md (if architectural change)
8. Verify cross-references
9. Commit together
```

## Context Loading Strategy

### Before (1433 lines)
- Single CLAUDE.md file
- All context loaded every time
- ~50,000 tokens baseline
- 25%+ of context window consumed

### After (200-400 lines typical)
- CLAUDE.md: 200 lines (navigation)
- Task-specific docs: 100-200 lines
- Total: 300-400 lines typical
- 60-70% reduction in context

### Example Flow
```
User: "Add Alacritty configuration"
↓
Main Claude: Reads CLAUDE.md (200 lines)
↓
Main Claude: Sees "adding features → docs/development/adding-features.md"
↓
Main Claude: Reads adding-features.md (200 lines)
↓
Main Claude: Creates integration checklist
↓
Total context: ~400 lines vs 1433 lines (72% reduction)
```

## Sub-Agent Context Strategy

### product-manager Agent
**Always reads first:**
- docs/development/adding-features.md (feature checklist)

**Reads as needed:**
- docs/development/package-management.md (Stow understanding)
- docs/security/patterns.md (security requirements)
- docs/reference/dotfiles-commands.md (workflow commands)

### architecture-assistant Agent
**Always reads first:**
- docs/architecture/overview.md (system architecture)

**Reads as needed:**
- docs/development/package-management.md (GNU Stow patterns)
- docs/security/multi-machine.md (config layering)
- docs/development/shell-patterns.md (shell module design)

### shell-validator Agent
**Always reads first:**
- docs/development/shell-patterns.md (shell best practices)
- docs/security/patterns.md (security requirements)

**Reads as needed:**
- docs/quality/code-standards.md (quality requirements)

### security-auditor Agent
**Always reads first:**
- docs/security/patterns.md (security patterns)
- docs/security/auditing.md (audit process)

**Reads as needed:**
- docs/security/multi-machine.md (machine config isolation)
- docs/development/shell-patterns.md (shell security)

## Navigation Patterns

### Decision Tree in CLAUDE.md
```markdown
## Finding Information - Decision Tree

**When working on...**

### Adding New Features
→ Read: docs/development/adding-features.md (CRITICAL - has checklist)
→ Use: product-manager agent for planning

### GNU Stow Packages
→ Read: docs/development/package-management.md
→ Use: architecture-assistant agent

### Shell Scripts
→ Read: docs/development/shell-patterns.md
→ Read: shell/AGENTS.md
→ Use: shell-validator agent

### Security
→ Read: docs/security/patterns.md
→ Use: security-auditor agent
```

### Cross-References
All docs/ files MUST include cross-references to related docs at the end:

```markdown
## Cross-References

- docs/development/adding-features.md (Feature integration)
- docs/security/patterns.md (Security requirements)
- docs/development/testing-debugging.md (Testing approaches)
```

## Documentation Quality Metrics

### Success Criteria
- CLAUDE.md ≤ 200 lines
- Each docs/ file 100-200 lines (focused)
- 60-70% reduction in typical context consumption
- Navigation is intuitive (agents find info quickly)
- No duplicated content across files

### Maintenance Metrics
- Documentation updated with code changes
- All links verified working
- Cross-references accurate
- Agent Rules compliance maintained

## Cross-References

- CLAUDE.md (Primary context)
- docs/quality/documentation-standards.md (Standards)
- docs/architecture/agent-integration.md (How agents use docs)
