# PR Review Workflow

Step-by-step workflow for reviewing pull requests without making code changes.

## When to Use

Use this workflow when the user wants:
- PR status overview
- Merge blocker identification
- CI/CD checks status
- Review comment analysis
- Health metrics assessment
- **NOT** making fixes (for fixes, see fix-workflow.md)

## Prerequisites

Before starting, verify:
1. GitHub CLI (`gh`) is installed: `command -v gh`
2. User is authenticated: `gh auth status`
3. In a repository with a PR or PR number/URL provided

## Step 1: Identify the Pull Request

If the user didn't provide a PR number/URL:
```bash
# Show current branch's PR
gh pr view
```

If user provided a PR number:
```bash
gh pr view <number>
```

If user provided a URL:
```bash
gh pr view <url>
```

## Step 2: Fetch Comprehensive PR Data

Gather all relevant PR information in parallel for efficiency:

```bash
# Get PR details (status, mergeable state, draft status, review decision)
gh pr view <pr> --json number,title,state,isDraft,mergeable,mergeStateStatus,reviewDecision,url,author,baseRefName,headRefName,additions,deletions,changedFiles,createdAt,updatedAt

# Get CI/CD checks status
gh pr checks <pr> --json name,state,bucket,conclusion,link,description

# Get ALL THREE types of comments:

# 1. Issue comments (general PR discussion)
gh api repos/{owner}/{repo}/issues/<pr>/comments

# 2. Review comments (inline code comments)
gh api repos/{owner}/{repo}/pulls/<pr>/comments

# 3. Review summaries (approve/changes requested)
gh api repos/{owner}/{repo}/pulls/<pr>/reviews

# Get review threads with resolution status
gh pr view <pr> --json reviewThreads

# Get review status
gh pr view <pr> --json reviews,latestReviews,reviewRequests
```

See [../reference/gh-commands.md](../reference/gh-commands.md) for detailed command documentation.
See [../reference/comment-types.md](../reference/comment-types.md) for explanation of three comment types.

## Step 3: Initial Data Analysis

For each data point, identify:

### Merge Blockers

- Is PR in draft state? (`isDraft: true`)
- Are CI checks failing? (any check with `state: "FAILURE"` or `bucket: "fail"`)
- Is PR mergeable? (`mergeable: "CONFLICTING"` means conflicts)
- Review status? (`reviewDecision: "CHANGES_REQUESTED"` or no approvals)
- Pending checks? (any check with `state: "PENDING"`)

### Unresolved Comments

Parse ALL three types of comments:

1. **Issue comments** (general PR discussion):
   - Check for questions without answers
   - Look for feedback not addressed
   - Recent general concerns

2. **Review comments** (inline code comments):
   - Check `isResolved: false` in review threads
   - Comments without replies from author
   - Suggestions not implemented

3. **Review summaries** (overall review):
   - Reviews with `state: "CHANGES_REQUESTED"`
   - Review body text with actionable feedback
   - Multiple reviewers' decisions

**Priority indicators:**
- "CHANGES_REQUESTED" review = HIGH priority
- Unresolved thread on security/bug = CRITICAL
- General question/suggestion = MEDIUM
- Resolved or outdated = IGNORE

### PR Health Metrics

- Size: Lines changed (additions + deletions)
- Age: Time since creation
- Activity: Time since last update
- Files changed count

## Step 3.5: Deep Analysis with Extended Thinking

**CRITICAL: Use extended thinking to thoroughly analyze all PR data.**

After collecting all data from Step 2, engage extended thinking mode to:

### Phase 1: Comprehensive Data Review
Think deeply about:
- All comments (issue, review, summary) - what patterns emerge?
- All check failures - what do they indicate about code quality?
- All review threads - what are reviewers truly concerned about?
- PR size and complexity - is this manageable or should it be split?
- Timeline and urgency - how long has this been open?

### Phase 2: Root Cause Analysis
For each blocker or comment, analyze:
- **What is the actual problem?** (not just symptoms)
- **Why does this problem exist?** (architectural? oversight? misunderstanding?)
- **What needs to change?** (specific files, patterns, approaches)
- **Are there related issues?** (might fixing one require fixing others?)
- **What's the best approach?** (quick fix vs proper refactor?)

### Phase 3: Create Structured Action Plan

Generate a detailed, actionable list with:

```markdown
## Analysis Results

### Critical Issues (Must Fix Before Merge)
1. **[Issue Type]** in `file.js:123`
   - **Problem**: Detailed description of what's wrong
   - **Root Cause**: Why this happened
   - **Fix Approach**: Specific steps to resolve
   - **Estimated Complexity**: [Simple/Medium/Complex]
   - **Dependencies**: What else needs to change
   - **Testing Strategy**: How to verify the fix

### High Priority Issues (Should Fix)
[Same structure as Critical]

### Medium Priority Issues (Good to Fix)
[Same structure as Critical]

### Low Priority Issues (Optional Improvements)
[Same structure as Critical]

## Implementation Plan

### Recommended Order of Operations
1. Fix X first because Y
2. Then fix Z because it depends on X
3. ...

### Risk Assessment
- **High Risk Changes**: [List changes that could break things]
- **Safe Changes**: [List straightforward fixes]
- **Needs Discussion**: [List items requiring team input]

### Time/Effort Estimate
- Critical fixes: [X items - complexity assessment]
- High priority: [Y items - complexity assessment]
- Total effort: [Realistic assessment]

### Verification Strategy
1. Run tests after each fix
2. Verify specific scenarios work
3. Check for regressions in related areas
```

### Phase 4: Consider Context and Trade-offs
Think about:
- **Team dynamics**: Who requested changes? Are there disagreements?
- **Architectural implications**: Do fixes align with project patterns?
- **Technical debt**: Are we creating or reducing it?
- **Alternative approaches**: Could we solve this differently?
- **Communication needs**: What should be explained to reviewers?

### Output from Extended Thinking

After extended thinking, you should have:
1. ✅ Clear understanding of every issue and blocker
2. ✅ Structured list of problems with solutions
3. ✅ Prioritized action plan with dependencies mapped
4. ✅ Risk assessment for each proposed fix
5. ✅ Verification strategy to ensure quality
6. ✅ Communication plan for reviewers/team

**Important**: The extended thinking output forms the foundation for Steps 4 and 5. Don't skip this step - it's the difference between a basic status check and a truly helpful analysis.

## Step 4: Create Trackable Markdown Action Plan

**CRITICAL: Create a markdown checklist that can be tracked during implementation.**

Convert your extended thinking analysis into a structured markdown checklist:

### Markdown Checklist Format

```markdown
## 📋 Action Plan

### 🔴 Critical Issues (Must Fix Before Merge)
- [ ] **Fix [issue] in `file.js:line`**
  - **Problem**: What's wrong
  - **Root Cause**: Why this happened
  - **Fix**: Specific solution
  - **Complexity**: Simple/Medium/Complex (X min)
  - **Dependencies**: Related changes needed or "None"
  - **Testing**: How to verify

### 🟡 High Priority, 🟢 Medium Priority, ⚪ Low Priority
[Same format for each priority level]

### ✅ Verification Steps
- [ ] Run test suite: `npm test`
- [ ] Run linter and build
- [ ] Verify CI/CD checks pass

---

**Implementation Plan:**
1. Fix critical first (with rationale)
2. Then high priority
3. Run verification after critical/high fixes

**Risk Assessment:**
- **High Risk**: Changes that could break functionality
- **Low Risk**: Isolated changes

**Total Time Estimate**: ~X minutes
**Needs Discussion**: Items requiring team input or "None"
```

### Guidelines for Creating the Checklist

1. **Be specific**: Include file paths and line numbers
2. **Show root cause**: Explain why the issue exists
3. **Detail the fix**: Specific approach, not just "fix it"
4. **Estimate complexity**: Simple/Medium/Complex with time
5. **Identify dependencies**: What else needs to change
6. **Include testing**: How to verify each fix
7. **Add verification section**: Overall testing strategy
8. **Provide implementation order**: Sequence with rationale
9. **Assess risk**: High/Medium/Low risk for each item
10. **Estimate time**: Realistic total effort

**Important**: This markdown checklist will be included in your report so the user can track progress manually as items are completed.

## Step 5: Generate Comprehensive Report

Structure your report using this format:

```markdown
# PR Review: #<number> - <title>

## 🎯 Status Overview

**Current State:** [READY / BLOCKED / PENDING REVIEW / DRAFT]
**Mergeable:** [Yes / No - Conflicts exist]
**Review Decision:** [Approved / Changes Requested / Review Required]

## 📋 Trackable Action Plan

[Insert the complete markdown checklist from Step 4 here]

**Summary:**
- X Critical issues (must fix before merge)
- Y High priority issues (should fix)
- Z Medium/Low priority items (improvements)
- Verification steps to ensure quality

Copy this checklist to track your progress as you work through the fixes.

## 🚦 CI/CD Checks

### Passing ✅
- check-name (link)

### Failing ❌
- check-name: reason (link)

### Pending ⏳
- check-name (link)

## 🚧 Merge Blockers

[If any blockers exist, list them with clear action items]

1. **Blocker type**: Description
   - **Action needed**: What to do to resolve

[If no blockers:]
✅ No blockers detected - PR appears ready to merge!

## 💬 Discussion Status

### Unresolved Comments: X

**Review Comments (inline code):**
- **File**: `path/to/file.js:123`
  - **Reviewer**: @username
  - **Thread**: Unresolved
  - **Comment**: "Summary of concern"
  - **Action**: What needs addressing

**Issue Comments (general feedback):**
- **PR Comment** by @username (3 hours ago)
  - **Comment**: "General concern or question"
  - **Action**: What needs addressing

**Review Summaries (overall review):**
- **@reviewer** requested changes
  - **Summary**: "Overall feedback in review body"
  - **Action**: What needs addressing

[If no unresolved comments:]
✅ All review comments have been addressed and resolved.

### Recent Activity
- Last updated: X hours/days ago
- Latest comment: Brief summary

## 🔍 Deep Analysis & Action Plan

**NOTE**: This section is generated from the extended thinking analysis in Step 3.5.

### Critical Issues (Must Fix Before Merge)
[From extended thinking Phase 3]

1. **[Issue Type]** in `file.js:123`
   - **Problem**: What's wrong
   - **Root Cause**: Why this happened
   - **Fix Approach**: How to resolve it
   - **Complexity**: Simple/Medium/Complex
   - **Dependencies**: Related changes needed
   - **Testing**: How to verify

### High Priority Issues (Should Fix)
[Same structure]

### Medium Priority Issues (Good to Fix)
[Same structure]

### Low Priority Issues (Optional)
[Same structure]

### Implementation Plan

**Recommended Order of Operations:**
1. [Step with rationale]
2. [Step with rationale]
...

**Risk Assessment:**
- **High Risk**: Changes that could break functionality
- **Safe**: Straightforward fixes
- **Needs Discussion**: Items requiring team alignment

**Effort Estimate:**
- Critical: X items (complexity breakdown)
- High: Y items (complexity breakdown)
- Total: Realistic time/effort assessment

**Verification Strategy:**
1. Tests to run after each fix
2. Scenarios to verify
3. Areas to check for regressions

## 📊 PR Health Metrics

- **Size**: X additions, Y deletions (Z total)
- **Size assessment**: [Small/Medium/Large/Too Large - see best practices]
- **Files changed**: N files
- **Age**: X days old
- **Branch**: `head-branch` → `base-branch`

## ✅ Best Practices Assessment

[Compare PR against best practices - see ../reference/best-practices.md]

### Strengths 💪
- What this PR does well

### Improvement Opportunities 🎯
- Suggestions based on best practices

## 🎬 Recommended Next Steps

**Immediate Actions:**
1. [Priority 1 with specific command/action]
2. [Priority 2 with specific command/action]

**After Fixes:**
1. [What to do once issues are resolved]
2. [Communication steps]

**Would you like me to implement these fixes?**
- I can address the issues systematically following the plan above
- Or we can discuss specific items first

---

**PR URL**: <url>
**Review generated**: <timestamp>
```

## Step 6: Provide Actionable Recommendations

Based on the analysis and todo list, suggest:
- Specific commands to run (e.g., `gh pr ready` to mark as ready)
- Files that need attention
- Which reviewers to ping
- Whether to merge or wait

If user wants to make fixes, suggest using the fix workflow:
```
Would you like me to fix these issues? I can:
- Address review comments
- Fix failing tests
- Resolve merge conflicts
```

## Best Practices Reference

This skill incorporates research-backed PR best practices. See [../reference/best-practices.md](../reference/best-practices.md) for:
- Ideal PR size (200-400 LOC recommended)
- Required checks before merge
- Code review quality criteria
- Documentation requirements
- Testing standards

## Examples

See [../examples/review-examples.md](../examples/review-examples.md) for sample outputs and common scenarios.

## Error Handling

If any command fails:
1. Explain what went wrong clearly
2. Suggest how to fix (e.g., "Run `gh auth login` to authenticate")
3. Provide alternative approaches if available

## Notes

- Always fetch fresh data - don't rely on cached information
- Use parallel commands where possible for speed
- Be objective in assessment - use data, not assumptions
- Prioritize merge blockers in your report
- Provide actionable next steps, not just observations
