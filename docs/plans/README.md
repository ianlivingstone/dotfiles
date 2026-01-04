# Plan Management Guide

This directory contains forward-looking plans for repository improvements and features.

## Directory Structure

```
docs/plans/
├── README.md                    # This file
├── template.md                  # Plan template for new plans
└── YYYY-MM-plan-name.md         # Individual plans with status field
```

## Plan Lifecycle

Plans use a status field instead of subdirectories, following ADR patterns:

1. **Draft** → Created in `docs/plans/` with `Status: Draft`
2. **In Progress** → Update to `Status: In Progress` when implementation begins
3. **Implemented** → Update to `Status: Implemented` + add completion summary
4. **Superseded** → Update to `Status: Superseded` + link to replacement plan

## Creating a New Plan

1. Copy `template.md` to `docs/plans/YYYY-MM-plan-name.md`
2. Fill in all sections with status set to `Draft`
3. Commit: "Add [plan-name] for review"
4. Get feedback and approval
5. Update status to `In Progress` when starting implementation
6. Track progress with checkboxes
7. Update documentation as you implement (not before)
8. Add implementation summary when complete
9. Update status to `Implemented`

## Status Field Format

```markdown
**Status**: Draft | In Progress | Implemented | Superseded
**Created**: YYYY-MM-DD
**Started**: YYYY-MM-DD (when implementation begins)
**Completed**: YYYY-MM-DD (when finished)
**Superseded By**: [link] (if superseded)
```

## Plan Template Sections

- **Purpose**: What problem does this solve?
- **Current State**: What exists today?
- **Proposed Changes**: What should we do?
- **Implementation Checklist**: Trackable items
- **Documentation Impact**: What docs need updates?
- **Success Criteria**: How do we know it's done?
- **Implementation Summary**: Added when status changes to "Implemented"

## Should Plans Be Checked In?

**YES** - Plans should be committed to git because:
- **Transparency**: Shows decision-making process
- **History**: Documents why architectural choices were made
- **Collaboration**: Others can review and provide feedback
- **Reference**: Implemented plans serve as architectural decision records (ADRs)
- **Learning**: Others can learn from the planning process

## Commit Strategy

- Commit initial draft: "Add [plan-name] for review"
- Commit with feedback: "Update [plan-name] based on feedback"
- Commit when starting: "Begin implementing [plan-name]"
- Commit when complete: "Complete [plan-name] implementation"

## Documentation Updates

**When Creating a Plan**:
1. Review existing docs first to understand current state
2. Reference documentation in the plan (don't duplicate)
3. Note documentation impact in each recommendation
4. Don't update docs yet - wait for plan approval

**When Plan is Approved**:
1. Create implementation branch (if needed)
2. Update documentation as you implement (not before)
3. Documentation updates are part of implementation
4. Commit docs with related code changes

**Documentation Update Order**:
1. Implement feature code
2. Update technical docs (CLAUDE.md, AGENTS.md, docs/)
3. Update user-facing docs (README.md)
4. Update ARCHITECTURE.md (if architectural change)
5. Commit all together

## Benefits of Status Field Approach

- ✅ No need to move files between directories
- ✅ Git history stays with the plan file
- ✅ Easier to see status evolution in git log
- ✅ Follows ADR pattern (single directory, status field)
- ✅ Simpler directory structure

## Related Documentation

- **Architecture Decision Records**: See `docs/adr/` for historical decisions
- **Development Guides**: See `docs/development/` for implementation patterns
- **Architecture Overview**: See `ARCHITECTURE.md` for high-level design

## Research Sources

This approach is based on industry standards:
- [Architecture Decision Records (ADRs)](https://adr.github.io/)
- [AWS: ADR Process](https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html)
- [Microsoft Azure: Maintain an ADR](https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record)
- [Google Cloud: Architecture Decision Records](https://docs.cloud.google.com/architecture/architecture-decision-records)
