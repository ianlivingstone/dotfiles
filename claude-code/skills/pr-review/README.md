# PR Review Skill

Comprehensive GitHub pull request review and merge readiness assessment using GitHub CLI.

## Overview

This skill automatically activates when you ask Claude about pull request status, checks, or merge blockers. It uses `gh` (GitHub CLI) to fetch comprehensive PR data and provides actionable insights.

## Features

### Review Mode
- **Comprehensive PR Analysis**: Fetches status, checks, comments, and reviews
- **Merge Blocker Detection**: Identifies what's preventing merge (conflicts, failing checks, reviews needed)
- **Best Practices Assessment**: Evaluates PR against research-backed guidelines
- **Unresolved Comments**: Highlights discussions needing attention
- **Health Metrics**: PR size, age, activity, and quality indicators
- **Actionable Recommendations**: Prioritized next steps with commands to run

### Fix Mode (NEW!)
- **Automatic Fix Implementation**: Makes code changes to address review feedback
- **Failing Test Resolution**: Debugs and fixes failing CI/CD tests
- **Merge Conflict Resolution**: Helps resolve conflicts by analyzing both sides
- **Priority-Based Fixes**: Handles critical issues first (security, bugs, then style)
- **Verification**: Runs tests and linting after each fix
- **Safety Checks**: Confirms scope before making changes, never skips tests

## Automatic Triggers

This skill activates when you say things like:

### Review Requests
- "Review PR #123"
- "What's blocking my pull request?"
- "Is this PR ready to merge?"
- "Check the status of pull request https://github.com/org/repo/pull/456"
- "Review the current PR"
- "What do reviewers think about my PR?"

### Fix Requests (NEW!)
- "Fix the review comments on PR #123"
- "Address the PR feedback"
- "Fix the failing tests"
- "Resolve the merge conflicts"
- "Fix what @reviewer asked for"
- "Implement the suggested changes"

## Prerequisites

1. **GitHub CLI installed:**
   ```bash
   brew install gh
   # or: gh is likely already installed
   ```

2. **GitHub authentication:**
   ```bash
   gh auth login
   gh auth status  # Verify
   ```

3. **In a repository or provide PR URL/number**

## Usage Examples

### Check Current Branch's PR
```
Review my PR
```

Claude will automatically fetch the PR for your current branch.

### Check Specific PR by Number
```
Review PR #456
```

### Check PR by URL
```
Review https://github.com/myorg/myrepo/pull/789
```

### Find Merge Blockers
```
What's blocking PR #123?
```

Claude will focus on blockers: failing checks, conflicts, unresolved comments, etc.

### Quick Merge Check
```
Is PR #456 ready to merge?
```

Claude provides a clear YES/NO answer with reasoning.

## Fix Workflow

When you ask to fix PR feedback, the skill follows this process:

### 1. Fetch and Analyze
```
- Retrieves all review comments with file/line context
- Gets failing check details and test output
- Checks for merge conflicts
- Prioritizes issues by severity
```

### 2. Present Plan
```markdown
I found 5 review comments to address:

🔴 Critical (1)
- SQL injection vulnerability in auth.js

🟡 High Priority (2)
- Missing error handling in api/users.js
- Failing test: "User creation"

🟢 Medium (2)
- Code style improvements
- Documentation updates

Would you like me to:
A) Fix all issues
B) Fix only critical/high priority
C) Let you choose specific issues
```

### 3. Implement Fixes
For each issue:
- Reads relevant code
- Makes minimal, targeted changes
- Runs tests after each fix
- Verifies fix resolves the issue

### 4. Verification
- Runs full test suite
- Checks linting
- Verifies build succeeds
- Reviews all changes

### 5. Summary
```markdown
Fixed (5 issues):
✅ Security: SQL injection fixed
✅ Tests: All passing
✅ Documentation: Updated
✅ Style: Improved

Next steps:
1. Review changes: git diff
2. Push to PR: git push
3. Notify reviewers
```

## What the Skill Provides

### 1. Status Overview
- Current state (READY/BLOCKED/DRAFT/PENDING)
- Mergeable status (conflicts detected)
- Review decision (approved/changes requested/review required)

### 2. CI/CD Checks
- Passing checks ✅
- Failing checks ❌ with links and error details
- Pending checks ⏳

### 3. Merge Blockers
- Comprehensive list of what's preventing merge
- Priority ordering (critical → high → medium → low)
- Action items for each blocker
- Commands to run to resolve

### 4. Discussion Status
- Count of unresolved comments
- File-by-file breakdown of feedback
- Reviewer names and concerns
- Action needed for each comment

### 5. PR Health Metrics
- Size analysis (LOC with assessment)
- File count
- Age (days since creation)
- Activity (time since last update)
- Branch information

### 6. Best Practices Assessment
- What the PR does well
- Improvement opportunities
- Size recommendations
- Testing coverage notes
- Documentation quality

### 7. Recommended Next Steps
- Prioritized action list
- Specific commands to run
- Estimated effort/priority

## Best Practices Included

The skill evaluates PRs against research-backed best practices:

### PR Size Guidelines
- **Ideal**: 100-200 LOC
- **Good**: 200-400 LOC
- **Large**: 400-1000 LOC (consider splitting)
- **Too Large**: 1000+ LOC (definitely split)

Based on LinearB's 2025 study showing cycle time doubles over 200 LOC.

### Merge Readiness Checklist
- [ ] All CI checks passing
- [ ] At least 1 approval from qualified reviewer
- [ ] No unresolved comments or change requests
- [ ] No merge conflicts
- [ ] Code is tested (tests included and passing)
- [ ] Documentation updated (if needed)
- [ ] Branch is up-to-date with target
- [ ] PR is marked as ready (not draft)

### Quality Criteria
- Focused changes (single purpose)
- Comprehensive test coverage
- Clear documentation
- Follows project style guide
- Security vulnerabilities addressed
- Performance considerations

## File Structure

```
claude-code/skills/pr-review/
├── SKILL.md                        # Core skill (256 lines with @references)
├── README.md                       # User documentation
├── workflows/
│   ├── review-workflow.md          # Review-only workflow (detailed)
│   ├── fix-workflow.md             # Fix workflow (detailed)
│   └── safety-guidelines.md        # Comprehensive safety rules
├── reference/
│   ├── comment-types.md            # GitHub's 3 comment types explained
│   ├── best-practices.md           # Research-backed PR guidelines
│   └── gh-commands.md              # GitHub CLI command reference
└── examples/
    ├── review-examples.md          # Examples 1-4 (review mode)
    └── fix-examples.md             # Examples 5-8 (fix mode)
```

When stowed, this entire structure becomes available at `~/.claude/skills/pr-review/`

**Key improvements:**
- **SKILL.md reduced from 623 → 256 lines** (59% reduction)
- Modular structure with clear separation of concerns
- Fast context loading with @reference links
- Easy to navigate and maintain

## Tool Access

This skill has access to:
- `Bash` - For running gh CLI commands and git operations
- `Read` - For reading files
- `Write` - For generating reports
- `Edit` - For making code changes (fix mode only)
- `Grep` - For searching code
- `Glob` - For file pattern matching

**Permission mode:** `acceptEdits` - User approval required before code modifications

## GitHub CLI Commands Used

The skill uses these `gh` commands:

```bash
# View PR details
gh pr view <pr> --json <fields>

# Check CI/CD status
gh pr checks <pr> --json name,state,bucket,conclusion,link

# View comments
gh pr view <pr> --comments

# View reviews
gh pr view <pr> --json reviews,latestReviews,reviewRequests
```

## Customization

### Modify Best Practices
Edit `best-practices.md` to:
- Add company-specific guidelines
- Adjust LOC thresholds
- Include team-specific requirements
- Add custom checklist items

### Adjust Skill Behavior
Edit `SKILL.md` to:
- Change tool restrictions
- Modify report format
- Add additional checks
- Adjust trigger phrases in description

After changes:
```bash
./dotfiles.sh reinstall  # Restow changes to ~/.claude/
```

## Types of Fixes Supported

The skill can automatically fix:

### ✅ Supported
- **Code issues**: Logic errors, missing error handling, security vulnerabilities
- **Failing tests**: Test code updates, mock data fixes, timeout adjustments
- **Merge conflicts**: Analyzes both sides and helps resolve
- **Documentation**: README updates, API doc corrections, comment improvements
- **Code style**: Formatting, naming, structure (when clear)
- **Missing tests**: Adds test cases for edge cases

### ⚠️ Requires Guidance
- **Architectural changes**: Major refactoring, design pattern changes
- **Breaking changes**: API changes, database schema changes
- **Performance optimizations**: May need profiling data
- **Ambiguous feedback**: "This could be better" without specifics

### ❌ Not Supported
- **Changes to main/master**: Only works on PR branches
- **Skipping tests**: Will never disable tests to pass checks
- **Blind fixes**: Won't modify code without understanding it

## Safety Guidelines

The skill follows strict safety rules:

**Always:**
- Confirms scope with you before making changes
- Reads code before modifying
- Runs tests after each change
- Makes minimal, targeted changes
- Keeps you informed of progress

**Never:**
- Makes changes without your approval
- Skips testing to pass checks
- Forces push to protected branches
- Disables linting or test requirements
- Makes unrelated "improvements"

**Asks you if:**
- Multiple valid approaches exist
- Change might have side effects
- Tests are missing for the area
- Breaking change might be needed

## Troubleshooting

### Skill not triggering
- Try exact phrases: "Review PR #123" or "Fix the review comments"
- Verify skill loaded: Ask Claude "What skills are available?"
- Check Claude Code started after skill installation

### GitHub CLI errors
```bash
# Not authenticated
gh auth login

# Wrong repository
cd /path/to/correct/repo

# PR not found
gh pr list  # See available PRs

# Can't checkout PR branch (uncommitted changes)
git stash  # Save local changes first
```

### Tests fail after fix
The skill verifies each fix, but if tests fail:
1. Review the changes: `git diff`
2. Run tests locally: `npm test` (or appropriate command)
3. Ask Claude to iterate: "The test is still failing, can you fix it?"

### Slow performance
The skill fetches comprehensive data which may take a few seconds for large PRs with many comments.

## Sources and Research

Best practices synthesized from:
- [GitHub Pull Request Best Practices (2024-2026)](https://rewind.com/blog/best-practices-for-reviewing-pull-requests-in-github/)
- [LinearB Study: PR Size vs Cycle Time](https://linearb.io/)
- [Microsoft Engineering Playbook: Pull Requests](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/pull-requests/)
- [GitHub Staff Engineer: Code Review Philosophy](https://github.blog/developer-skills/github/how-to-review-code-effectively-a-github-staff-engineers-philosophy/)
- [Complete Guide to Code Reviews | Swarmia](https://www.swarmia.com/blog/a-complete-guide-to-code-reviews/)

See `best-practices.md` for full citations and detailed guidelines.

## Feedback and Improvements

This skill is part of the global Claude Code harness. To suggest improvements:

1. **For this specific skill**: Edit files in `claude-code/skills/pr-review/`
2. **For skill system**: See `claude-code/skills/README.md`
3. **For dotfiles integration**: See `docs/development/claude-code-integration.md`

---

**Version:** 2.0.0 (Added automatic fix capabilities)
**Created:** 2026-01-04
**Last Updated:** 2026-01-04
**Maintainer:** Dotfiles repository

## Changelog

### v2.0.0 (2026-01-04)
- ✨ **NEW**: Automatic fix implementation for review comments
- ✨ **NEW**: Failing test resolution
- ✨ **NEW**: Merge conflict resolution assistance
- ✨ **NEW**: Priority-based fix workflow (critical → high → medium → low)
- ✨ **NEW**: Safety checks and user confirmation before changes
- ✨ **NEW**: Verification after each fix (tests, linting, build)
- 📚 Added 3 new examples (fixing comments, failing tests, conflicts)
- 📚 Comprehensive fix workflow documentation

### v1.0.0 (2026-01-04)
- Initial release
- Comprehensive PR review and analysis
- Merge blocker detection
- Best practices assessment
- CI/CD checks monitoring
- Unresolved comments tracking
