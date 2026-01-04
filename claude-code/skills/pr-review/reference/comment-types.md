# GitHub PR Comment Types - Quick Reference

GitHub has THREE distinct types of comments on pull requests. The pr-review skill fetches ALL of them.

## The Three Comment Types

### 1. Issue Comments (General PR Discussion)
**What**: Comments on the PR itself, not tied to specific code
**Where**: PR conversation tab
**API**: `/repos/{owner}/{repo}/issues/{pr}/comments`

**Examples:**
- "Great work! One question about the approach..."
- "Can we add tests for edge case X?"
- "This breaks backwards compatibility, we need a migration guide"

**When to address:**
- Questions from reviewers
- General concerns about approach
- Feature requests
- Discussion about requirements

### 2. Review Comments (Inline Code Comments)
**What**: Comments on specific lines of code in files
**Where**: Files changed tab, inline with code
**API**: `/repos/{owner}/{repo}/pulls/{pr}/comments`

**Examples:**
- Line 45 in `auth.js`: "This has a SQL injection vulnerability"
- Line 123 in `utils.ts`: "Extract this into a helper function"
- Line 67 in `test.js`: "Missing test case for null input"

**When to address:**
- Code-specific feedback
- Security issues on specific lines
- Refactoring suggestions
- Style issues

### 3. Review Summaries (Overall Review)
**What**: The overall review with approve/request changes/comment
**Where**: PR conversation tab, from reviewer
**API**: `/repos/{owner}/{repo}/pulls/{pr}/reviews`

**Review states:**
- `APPROVED` - Reviewer approves the changes
- `CHANGES_REQUESTED` - Reviewer requests changes before approval
- `COMMENTED` - Reviewer left comments without explicit approval/rejection

**Examples:**
- "Requesting changes: This PR needs comprehensive error handling"
- "Approved with minor suggestions"
- "Looks good overall, but see my comments about the race condition"

**When to address:**
- High-priority: `CHANGES_REQUESTED` reviews block merge
- Overall architectural concerns
- General feedback in review body

## How the Skill Fetches All Comments

### Review Mode (Just Reporting)

```bash
# Basic comment fetching
gh pr view <pr> --json reviewThreads  # Gets threads with resolution status
gh api repos/{owner}/{repo}/issues/<pr>/comments  # Issue comments
gh api repos/{owner}/{repo}/pulls/<pr>/comments   # Review comments
gh api repos/{owner}/{repo}/pulls/<pr>/reviews    # Review summaries
```

### Fix Mode (Making Changes)

```bash
# 1. Issue comments (general discussion)
gh api repos/{owner}/{repo}/issues/<pr>/comments --jq '.[] | {
  id, user: .user.login, body, created_at, type: "issue_comment"
}'

# 2. Review comments (inline code)
gh api repos/{owner}/{repo}/pulls/<pr>/comments --jq '.[] | {
  id, path, line, body, user: .user.login, created_at, type: "review_comment"
}'

# 3. Review summaries (overall review)
gh api repos/{owner}/{repo}/pulls/<pr>/reviews --jq '.[] | {
  id, user: .user.login, state, body, submitted_at, type: "review"
}'

# 4. Review threads (resolution status)
gh pr view <pr> --json reviewThreads --jq '.reviewThreads[] | {
  isResolved, isOutdated,
  comments: [.comments[] | {path, line, body, author: .author.login}]
}'
```

## Comment Organization

The skill organizes comments by:

### Priority
1. **CRITICAL**: `CHANGES_REQUESTED` reviews + security issues
2. **HIGH**: Unresolved threads on bugs/logic errors
3. **MEDIUM**: Style issues, documentation, test coverage
4. **LOW**: Suggestions, nice-to-haves

### Resolution Status
- **Unresolved**: `isResolved: false` - Must be addressed
- **Resolved**: `isResolved: true` - Already handled
- **Outdated**: `isOutdated: true` - Code changed, comment may not apply

### Source Type
- **Review comment**: Inline code feedback
- **Issue comment**: General PR discussion
- **Review summary**: Overall review decision

## Filtering Rules

### Include:
✅ Unresolved threads (`isResolved: false`)
✅ `CHANGES_REQUESTED` reviews
✅ Comments without replies from author
✅ Recent issue comments
✅ Questions needing answers

### Exclude:
❌ Resolved threads (`isResolved: true`)
❌ Outdated comments (`isOutdated: true`)
❌ Bot comments (CI status, automated checks)
❌ `APPROVED` reviews (unless they have body text with feedback)
❌ Comments already addressed in later commits

## Common Pitfalls

### ❌ Only fetching review comments
```bash
# INCOMPLETE - misses general discussion
gh api repos/{owner}/{repo}/pulls/<pr>/comments
```

### ❌ Only fetching issue comments
```bash
# INCOMPLETE - misses inline code feedback
gh api repos/{owner}/{repo}/issues/<pr>/comments
```

### ❌ Not checking resolution status
```bash
# INCOMPLETE - includes already-resolved feedback
gh api repos/{owner}/{repo}/pulls/<pr>/comments
# Missing: --json reviewThreads to check isResolved
```

### ✅ Complete fetching (what the skill does)
```bash
# Gets ALL three types PLUS resolution status
gh api repos/{owner}/{repo}/issues/<pr>/comments     # Type 1
gh api repos/{owner}/{repo}/pulls/<pr>/comments      # Type 2
gh api repos/{owner}/{repo}/pulls/<pr>/reviews       # Type 3
gh pr view <pr> --json reviewThreads                 # Resolution status
```

## Example: All Three Types on One PR

```
PR #123 Feedback:

Type 1 - Issue Comment:
  @product-manager: "Can we add logging for debugging?"

Type 2 - Review Comment:
  @security-team on auth.js:45: "SQL injection vulnerability"

Type 3 - Review Summary:
  @tech-lead: "Requesting changes: Race condition in payment processor"
```

**All three must be fetched and addressed for complete PR review.**

## Testing Comment Fetching

To verify the skill fetches all comment types:

```bash
# Create a test PR with all three types
# 1. Add general comment on PR
gh pr comment 123 --body "General feedback here"

# 2. Add inline review comment
gh pr review 123 --comment --body "Inline comment on line 45"

# 3. Request changes with review
gh pr review 123 --request-changes --body "Overall review feedback"

# Verify skill fetches all three
# Ask Claude: "Review PR #123"
# Check output includes all three comment types
```

## References

- **GitHub API docs**: https://docs.github.com/en/rest/pulls
- **gh CLI docs**: https://cli.github.com/manual/gh_pr
- **Review threads**: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/commenting-on-a-pull-request

---

**Last Updated:** 2026-01-04
**Part of:** pr-review skill v2.0.0
