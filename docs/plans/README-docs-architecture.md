# Documentation Architecture Design - Complete Package

**Created**: 2026-01-03
**Status**: Ready for Review
**Part of**: Claude Code Improvement Plan (Recommendation 1.1)

## Overview

This package contains the complete specification for transforming the dotfiles repository's documentation from a monolithic 1,433-line CLAUDE.md into a lean, task-oriented `docs/` structure that reduces context consumption by 60-70%.

## Package Contents

### 1. Executive Summary
**File**: [docs-architecture-summary.md](./docs-architecture-summary.md)
**Purpose**: Quick overview for decision-makers
**Length**: ~7 pages
**Read this if**: You want the high-level picture without deep details

**Key Points**:
- Problem: 1,433-line CLAUDE.md consumes 25%+ of context window
- Solution: 200-line CLAUDE.md + 15 focused docs/ files
- Impact: 60-70% context reduction in typical scenarios
- Critical innovation: Feature integration checklist (adding-features.md)

### 2. Full Specification
**File**: [docs-architecture-spec.md](./docs-architecture-spec.md)
**Purpose**: Complete technical specification
**Length**: ~40 pages
**Read this if**: You're implementing or need complete details

**Includes**:
- Complete docs/ directory structure (15 files)
- Content mapping from CLAUDE.md to docs/ files
- New CLAUDE.md structure (200 lines)
- Agent access patterns
- Implementation timeline (4 weeks)
- Success criteria
- Open questions for feedback

### 3. Visual Guide
**File**: [docs-architecture-visual.md](./docs-architecture-visual.md)
**Purpose**: Visual representations and diagrams
**Length**: ~15 pages
**Read this if**: You're a visual learner or want to see the flow

**Includes**:
- Before/after architecture diagrams
- Information flow comparisons
- Agent access pattern visualizations
- Context consumption examples
- Success metrics visualizations

### 4. This Index
**File**: README-docs-architecture.md (this file)
**Purpose**: Navigation and quick reference
**Read this first**: To understand what's in the package

## Quick Reference

### The Problem
```
Current: CLAUDE.md (1,433 lines)
         ↓ Loaded every time
         ↓ Consumes 50,000+ tokens
         ↓ 25%+ of context window
         ↓ Slow, expensive, hard to maintain
```

### The Solution
```
New: CLAUDE.md (200 lines - navigation index)
     ↓ References to docs/ as needed
     ↓ 15 focused files (100-200 lines each)
     ↓ 60-70% context reduction
     ↓ Fast, efficient, easy to maintain
```

### Key Innovation
```
docs/development/adding-features.md
├── 6-area integration checklist
│   ├── Installation support
│   ├── Reinstall support
│   ├── Update support
│   ├── Security considerations
│   ├── Documentation
│   └── Testing
└── Ensures features don't break workflows
```

## Reading Path by Role

### For Decision-Makers
1. Read: [docs-architecture-summary.md](./docs-architecture-summary.md)
2. Review: Impact comparison section
3. Decide: Approve or request changes

### For Implementers
1. Read: [docs-architecture-summary.md](./docs-architecture-summary.md) (context)
2. Read: [docs-architecture-spec.md](./docs-architecture-spec.md) (details)
3. Review: Implementation timeline
4. Reference: [docs-architecture-visual.md](./docs-architecture-visual.md) (as needed)

### For Visual Learners
1. Read: [docs-architecture-visual.md](./docs-architecture-visual.md)
2. Skim: [docs-architecture-summary.md](./docs-architecture-summary.md)
3. Deep dive: [docs-architecture-spec.md](./docs-architecture-spec.md) (as needed)

### For Reviewers
1. Read: [docs-architecture-summary.md](./docs-architecture-summary.md)
2. Review: docs/ structure in [docs-architecture-spec.md](./docs-architecture-spec.md)
3. Check: Content mapping (CLAUDE.md → docs/)
4. Validate: Agent access patterns
5. Provide: Feedback on open questions

## Key Metrics

### Size Reduction
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| CLAUDE.md | 1,433 lines | 200 lines | **86% reduction** |
| Typical task context | 1,433 + ~500 | 200 + ~400 | **68% reduction** |
| Time to find info | 3-5 minutes | 30 seconds | **6-10x faster** |

### File Organization
| Category | Files | Total Lines | Purpose |
|----------|-------|-------------|---------|
| architecture/ | 3 | 400 | High-level design |
| development/ | 7 | 1,350 | Development guides |
| security/ | 4 | 750 | Security patterns |
| reference/ | 2 | 400 | Quick reference |
| quality/ | 2 | 250 | Standards |
| **Total** | **18** | **3,150** | **Organized, focused** |

Note: Appears larger (3,150 vs 1,433), but agents read only relevant subset (200-600 lines typical vs 1,433 always).

## Critical Decisions to Review

### 1. Directory Structure
**Question**: Approve `docs/` subdirectory organization?
- architecture/ - System design
- development/ - Dev guides (including critical adding-features.md)
- security/ - Security patterns
- reference/ - Quick reference
- quality/ - Standards

**See**: [docs-architecture-spec.md](./docs-architecture-spec.md) - Complete docs/ Directory Structure

### 2. CLAUDE.md Size Target
**Question**: Is 200 lines the right size for CLAUDE.md?
- 50 lines: Quick reference
- 50 lines: Decision tree navigation
- 40 lines: Essential rules
- 20 lines: Key commands
- 30 lines: Repository navigation
- 10 lines: Agent coordination

**See**: [docs-architecture-spec.md](./docs-architecture-spec.md) - New CLAUDE.md Structure

### 3. Feature Integration Enforcement
**Question**: Should `adding-features.md` checklist be mandatory?
- Ensures install/reinstall/update/security are addressed
- Prevents features from breaking workflows
- Enforced by product-manager agent

**See**: [docs-architecture-spec.md](./docs-architecture-spec.md) - docs/development/adding-features.md section

### 4. Implementation Timeline
**Question**: Approve 4-week phased implementation?
- Week 1: Foundation + critical content (adding-features.md)
- Week 2: Reference & development guides
- Week 3: Remaining docs + CLAUDE.md restructure
- Week 4: Validation and testing

**See**: [docs-architecture-spec.md](./docs-architecture-spec.md) - Implementation Order

### 5. Agent Access Patterns
**Question**: Should agents read docs/ as specified?
- product-manager always reads adding-features.md
- architecture-assistant always reads package-management.md
- shell-validator always reads shell-patterns.md + security/patterns.md
- security-auditor always reads security/patterns.md + auditing.md

**See**: [docs-architecture-spec.md](./docs-architecture-spec.md) - Agent Access Patterns

## Implementation Readiness

### Prerequisites
- ✅ Agent infrastructure in place (4 specialized agents created)
- ✅ Improvement plan approved (Recommendation 1.1)
- ✅ Current CLAUDE.md analyzed (1,433 lines mapped)
- ✅ Content allocation complete (all sections mapped to docs/ files)
- ✅ Success criteria defined (60-70% reduction target)

### Ready to Start
- [ ] Review this package
- [ ] Approve directory structure
- [ ] Approve CLAUDE.md size target (200 lines)
- [ ] Approve feature integration checklist approach
- [ ] Approve implementation timeline
- [ ] Provide feedback on open questions

### After Approval
1. Create docs/ directory structure
2. Create adding-features.md (highest priority)
3. Extract content from CLAUDE.md systematically
4. Restructure CLAUDE.md to 200 lines
5. Update agent instructions
6. Test with agents
7. Validate success criteria

## Success Criteria Checklist

### Quantitative
- [ ] CLAUDE.md ≤ 200 lines (currently 1,433)
- [ ] 15+ focused docs/ files created
- [ ] Context reduction of 60-70% measured
- [ ] All agents successfully use docs/
- [ ] All documentation links work

### Qualitative
- [ ] Agents can quickly find relevant docs for tasks
- [ ] Feature integration checklist is comprehensive
- [ ] Navigation is intuitive (agents and humans)
- [ ] Documentation is maintainable (small, focused files)
- [ ] New contributors can quickly orient

### Validation
- [ ] product-manager agent uses adding-features.md successfully
- [ ] architecture-assistant agent uses package-management.md successfully
- [ ] shell-validator agent uses shell-patterns.md successfully
- [ ] security-auditor agent uses security docs successfully
- [ ] Feature addition workflow tested end-to-end

## Questions & Feedback

### Provide Feedback On

1. **Structure**: Does the docs/ organization make sense?
2. **Content**: Is content allocation appropriate?
3. **Size**: Is 200-line CLAUDE.md the right target?
4. **Timeline**: Is 4 weeks reasonable?
5. **Approach**: Any concerns with the implementation plan?

### How to Provide Feedback

1. Review the three main documents (summary, spec, visual)
2. Note concerns or questions inline
3. Check boxes for approvals
4. Add comments for any changes needed
5. Indicate priority adjustments if needed

### Open Questions from Spec

See [docs-architecture-spec.md](./docs-architecture-spec.md) - "Open Questions for Feedback" section for complete list.

## Next Steps

### Immediate (You)
1. Review this package
2. Read summary for high-level understanding
3. Review spec for detailed design
4. Check visual guide for flow understanding
5. Provide approval or feedback

### After Approval (harness-architect + agents)
1. Create docs/ directory structure
2. **Priority 1**: Create adding-features.md with feature checklist
3. Extract content from CLAUDE.md to docs/ files
4. Restructure CLAUDE.md to 200-line navigation index
5. Update agent instructions to reference docs/
6. Test with all agents
7. Validate success criteria
8. Mark Recommendation 1.1 as complete

### Timeline
- **Review**: 1-2 days
- **Implementation**: 4 weeks (phased)
- **Validation**: 3-5 days
- **Total**: ~5 weeks from approval to completion

## Related Documentation

### This Improvement Plan
- **Main plan**: [2026-01-improvement-plan.md](./2026-01-improvement-plan.md)
- **Recommendation**: 1.1 - Create Documentation Architecture
- **Priority**: HIGH
- **Status**: Specification ready for review

### Component Documentation
- **Current CLAUDE.md**: `/Users/ian/code/src/github.com/ianlivingstone/dotfiles/CLAUDE.md` (1,433 lines)
- **ARCHITECTURE.md**: High-level design principles
- **Component AGENTS.md**: shell/, nvim/, git/, ssh/, tmux/, etc.

### Agent Documentation
- **product-manager**: `.claude/agents/product-manager.md`
- **architecture-assistant**: `.claude/agents/architecture-assistant.md`
- **shell-validator**: `.claude/agents/shell-validator.md`
- **security-auditor**: `.claude/agents/security-auditor.md`

## Contact & Questions

This design was created by the **harness-architect agent** based on:
- Analysis of current CLAUDE.md (1,433 lines)
- Review of improvement plan (Recommendation 1.1)
- Understanding of agent infrastructure
- Industry best practices for documentation architecture

For questions or clarifications, refer back to the three main documents in this package.

---

**Ready for your review and feedback!**

This package provides everything needed to understand, evaluate, and implement the documentation architecture transformation for the dotfiles repository's Claude Code harness.
