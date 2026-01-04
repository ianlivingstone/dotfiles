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

## Step 3: Analyze PR Data

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

## Step 4: Generate Comprehensive Report

Structure your report using this format:

```markdown
# PR Review: #<number> - <title>

## 🎯 Status Overview

**Current State:** [READY / BLOCKED / PENDING REVIEW / DRAFT]
**Mergeable:** [Yes / No - Conflicts exist]
**Review Decision:** [Approved / Changes Requested / Review Required]

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

1. Priority action items in order
2. ...

---

**PR URL**: <url>
**Review generated**: <timestamp>
```

## Step 5: Provide Actionable Recommendations

Based on the analysis, suggest:
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
