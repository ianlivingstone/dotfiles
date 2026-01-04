# Documentation Architecture - Executive Summary

**Created**: 2026-01-03
**Full Specification**: [docs-architecture-spec.md](./docs-architecture-spec.md)

## The Problem

Current CLAUDE.md is 1,433 lines (~50,000+ tokens), consuming 25%+ of context window before any actual work begins. This hurts:
- Response speed
- Cost per interaction
- Information discoverability
- Maintainability

## The Solution

Transform CLAUDE.md into a **focused 200-line navigation index** that references a well-organized `docs/` structure with 15 task-oriented files.

## Key Changes at a Glance

### Before
```
CLAUDE.md (1,433 lines)
├── Project overview (122 lines)
├── GNU Stow details (228 lines)
├── macOS patterns (32 lines)
├── Multi-machine config (280 lines)
├── Testing (18 lines)
├── Security (244 lines)
├── Version management (3 lines)
├── Documentation (48 lines)
├── Command reference (303 lines)
├── Code quality (9 lines)
└── Claude Code config (68 lines)
```

### After
```
CLAUDE.md (200 lines - navigation index)
└── References to...

docs/
├── README.md (navigation guide)
├── architecture/ (3 files, 400 lines)
├── development/ (7 files, 1,350 lines)
├── security/ (4 files, 750 lines)
├── reference/ (2 files, 400 lines)
└── quality/ (2 files, 250 lines)
```

## Impact Comparison

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| CLAUDE.md size | 1,433 lines | 200 lines | **86% reduction** |
| Context for typical task | 1,433 lines | 400-600 lines | **60-70% reduction** |
| Time to find info | Scan 1,433 lines | Read decision tree + 1-2 docs | **Much faster** |
| Maintainability | One huge file | 15 focused files | **Much easier** |

## The Critical File: adding-features.md

The most important new file is `docs/development/adding-features.md` (200 lines), which provides a **feature integration checklist**:

### 6-Area Checklist
1. **Installation Support** - Does `./dotfiles.sh install` handle it?
2. **Reinstall Support** - Does `./dotfiles.sh reinstall` work?
3. **Update Support** - Does `./dotfiles.sh update` include it?
4. **Security** - No credentials, proper permissions?
5. **Documentation** - Updated README, AGENTS.md, docs/?
6. **Testing** - Complete cycle tested?

This ensures new features don't break existing workflows.

## New CLAUDE.md Structure (200 lines)

```markdown
# Dotfiles Project Context for Claude

## Quick Reference (50 lines)
Project overview, tech stack, key concepts

## Finding Information - Decision Tree (50 lines)
Adding features? → Read docs/development/adding-features.md
GNU Stow? → Read docs/development/package-management.md
Shell scripts? → Read docs/development/shell-patterns.md
Security? → Read docs/security/patterns.md
Testing? → Read docs/development/testing-debugging.md
Commands? → Read docs/reference/dotfiles-commands.md

## Essential Rules (40 lines)
Security (NEVER violate)
Architecture (MUST follow)
Documentation (MUST maintain)

## Key Commands (20 lines)
./dotfiles.sh status/reinstall/install/update

## Sub-Agent Coordination (10 lines)
Which agent for which task

## Repository Navigation (30 lines)
Key files and where to find details
```

## Agent Access Patterns

### Example: Adding a New Feature

**Current Flow (with 1,433-line CLAUDE.md)**:
1. Load CLAUDE.md (1,433 lines)
2. Scan for relevant sections
3. Read multiple sections (500+ lines)
4. Hope nothing is missed
5. **Total**: ~2,000 lines of context

**New Flow (with docs/ structure)**:
1. Load CLAUDE.md (200 lines)
2. See decision tree: "adding features → docs/development/adding-features.md"
3. Read adding-features.md (200 lines)
4. Read package-management.md if needed (250 lines)
5. **Total**: ~650 lines of context (67% reduction)

### Agent-Specific Access

**product-manager agent**:
- Always reads: `adding-features.md` (feature checklist)
- Reads as needed: `package-management.md`, `dotfiles-commands.md`

**architecture-assistant agent**:
- Always reads: `architecture/overview.md`
- Reads as needed: `package-management.md`, `shell-patterns.md`, `multi-machine.md`

**shell-validator agent**:
- Always reads: `shell-patterns.md`, `security/patterns.md`
- Reads as needed: `code-standards.md`

**security-auditor agent**:
- Always reads: `security/patterns.md`, `security/auditing.md`
- Reads as needed: `multi-machine.md`

## Complete docs/ Structure

```
docs/
├── README.md (100 lines - how to use this structure)
│
├── architecture/
│   ├── overview.md (150 lines)
│   ├── documentation-strategy.md (100 lines)
│   └── agent-integration.md (150 lines)
│
├── development/
│   ├── adding-features.md (200 lines) ⭐ CRITICAL
│   ├── package-management.md (250 lines)
│   ├── shell-patterns.md (200 lines)
│   ├── version-management.md (150 lines)
│   ├── testing-debugging.md (150 lines)
│   ├── macos-patterns.md (100 lines)
│   └── claude-code-integration.md (150 lines)
│
├── security/
│   ├── overview.md (150 lines)
│   ├── patterns.md (200 lines)
│   ├── multi-machine.md (250 lines)
│   └── auditing.md (150 lines)
│
├── reference/
│   ├── dotfiles-commands.md (300 lines)
│   └── quick-start.md (100 lines)
│
└── quality/
    ├── code-standards.md (150 lines)
    └── documentation-standards.md (100 lines)

Total: 15 focused files + supporting infrastructure
```

## Implementation Timeline

### Week 1: Foundation + Critical Content
- Create directory structure
- Create docs/README.md
- **Create docs/development/adding-features.md** (highest priority)
- Extract package-management.md
- Extract security/patterns.md
- Extract security/multi-machine.md

### Week 2: Reference & Development
- Extract dotfiles-commands.md
- Extract shell-patterns.md
- Create testing-debugging.md
- Create version-management.md

### Week 3: Remaining Docs + CLAUDE.md
- Create all remaining docs/ files
- **Rewrite CLAUDE.md** (reduce to 200 lines)
- Update agent instructions

### Week 4: Validation
- Test with all agents
- Verify context reduction
- Validate all links work
- Measure success criteria

## Expected Benefits

### For AI Agents
- **60-70% less context** consumed per task
- **Faster responses** (less to process)
- **Better accuracy** (focused information)
- **Clearer guidance** (task-oriented organization)
- **Enforced workflow integration** (adding-features.md checklist)

### For Human Developers
- **Easy to find information** (clear navigation)
- **Quick onboarding** (quick-start.md)
- **Better maintainability** (small, focused files)
- **Clear patterns** (comprehensive examples)
- **Feature checklist prevents mistakes**

### For the Project
- **Lower costs** (less token usage)
- **Better quality** (enforced patterns)
- **Easier to maintain** (organized structure)
- **Scalable** (can add more docs without bloat)

## Success Criteria

- [ ] CLAUDE.md ≤ 200 lines (86% reduction)
- [ ] 15+ focused docs/ files created
- [ ] 60-70% context reduction in typical tasks
- [ ] All agents can successfully use docs/
- [ ] Feature integration checklist comprehensive
- [ ] All documentation links work
- [ ] New contributors can quickly orient

## What Makes This Different

### Not Just Splitting a File
This is a complete **documentation architecture redesign**:
1. **Task-oriented organization** (not topic-based)
2. **Decision tree navigation** (not searching)
3. **Agent-specific access patterns** (not one-size-fits-all)
4. **Modular context loading** (not all-or-nothing)
5. **Feature integration enforcement** (not suggestions)

### The Critical Innovation: adding-features.md
This file ensures that when adding ANY new functionality, developers MUST consider:
- Installation workflow
- Reinstall workflow
- Update workflow
- Security implications
- Documentation needs
- Testing requirements

This prevents the common problem of "feature works on my machine, breaks on fresh install."

## Next Steps

1. **Review the full specification**: [docs-architecture-spec.md](./docs-architecture-spec.md)
2. **Provide feedback** on structure, content allocation, timeline
3. **Approve or request changes**
4. **Begin implementation** (starting with adding-features.md)

## Questions?

See the full specification for:
- Detailed content mapping (CLAUDE.md → docs/)
- Line-by-line file specifications
- Complete agent access patterns
- Implementation steps
- Success criteria
- Open questions

---

**Ready for your feedback!**

This architecture will transform the dotfiles Claude Code harness from context-heavy to context-efficient while improving discoverability, maintainability, and ensuring proper feature integration.
