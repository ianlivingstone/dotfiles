# GitHub CLI Commands Reference

Quick reference for `gh` CLI commands used in PR review and fix workflows.

## Prerequisites

```bash
# Install (if needed)
brew install gh

# Authenticate
gh auth login

# Verify authentication
gh auth status
```

## PR Viewing

```bash
# View current branch's PR
gh pr view

# View specific PR by number
gh pr view 123

# View PR by URL
gh pr view https://github.com/org/repo/pull/123

# View with all fields (JSON)
gh pr view 123 --json number,title,state,isDraft,mergeable,mergeStateStatus,reviewDecision,url,author,baseRefName,headRefName,additions,deletions,changedFiles,createdAt,updatedAt
```

## CI/CD Checks

```bash
# View checks for PR
gh pr checks 123

# View checks as JSON
gh pr checks 123 --json name,state,bucket,conclusion,link,description

# Watch checks (wait for completion)
gh pr checks 123 --watch

# View only required checks
gh pr checks 123 --required
```

## Comments - Three Types

See [comment-types.md](comment-types.md) for detailed explanation.

### 1. Issue Comments (General Discussion)

```bash
# List all issue comments
gh api repos/{owner}/{repo}/issues/123/comments

# With jq filtering
gh api repos/{owner}/{repo}/issues/123/comments --jq '.[] | {
  id, user: .user.login, body, created_at
}'

# Add issue comment
gh pr comment 123 --body "General feedback here"
```

### 2. Review Comments (Inline Code)

```bash
# List all review comments
gh api repos/{owner}/{repo}/pulls/123/comments

# With jq filtering
gh api repos/{owner}/{repo}/pulls/123/comments --jq '.[] | {
  id, path, line, body, user: .user.login, created_at
}'

# Add review comment (requires review)
gh pr review 123 --comment --body "Comment on specific line"
```

### 3. Review Summaries (Overall Review)

```bash
# List all reviews
gh api repos/{owner}/{repo}/pulls/123/reviews

# With jq filtering
gh api repos/{owner}/{repo}/pulls/123/reviews --jq '.[] | {
  id, user: .user.login, state, body, submitted_at
}'

# Request changes
gh pr review 123 --request-changes --body "Changes needed"

# Approve PR
gh pr review 123 --approve --body "LGTM!"

# Comment without approval/rejection
gh pr review 123 --comment --body "Some thoughts"
```

## Review Threads (Resolution Status)

```bash
# Get review threads with resolution status
gh pr view 123 --json reviewThreads

# Filter resolved/unresolved
gh pr view 123 --json reviewThreads --jq '.reviewThreads[] | select(.isResolved == false)'

# Check if outdated
gh pr view 123 --json reviewThreads --jq '.reviewThreads[] | select(.isOutdated == true)'
```

## PR Diff and Files

```bash
# View PR diff
gh pr diff 123

# View diff for specific file
gh pr diff 123 -- path/to/file.js

# List files changed
gh pr view 123 --json files --jq '.files[].path'

# List files with stats
gh pr view 123 --json files --jq '.files[] | {path, additions, deletions}'
```

## Branch Operations

```bash
# Checkout PR branch
gh pr checkout 123

# List PRs
gh pr list

# List PRs by author
gh pr list --author @me

# List PRs by state
gh pr list --state open
gh pr list --state closed
gh pr list --state merged
```

## PR Status Changes

```bash
# Mark PR as ready (from draft)
gh pr ready 123

# Mark PR as draft
gh pr ready 123 --undo

# Close PR
gh pr close 123

# Reopen PR
gh pr reopen 123

# Merge PR
gh pr merge 123 --squash
gh pr merge 123 --merge
gh pr merge 123 --rebase
```

## Useful Combinations

### Complete PR review data

```bash
# Fetch everything needed for review
gh pr view 123 --json number,title,state,isDraft,mergeable,mergeStateStatus,reviewDecision
gh pr checks 123 --json name,state,bucket,conclusion,link
gh api repos/{owner}/{repo}/issues/123/comments
gh api repos/{owner}/{repo}/pulls/123/comments
gh api repos/{owner}/{repo}/pulls/123/reviews
gh pr view 123 --json reviewThreads
```

### Check if PR is ready to merge

```bash
# All these should be true:
gh pr view 123 --json isDraft --jq '.isDraft == false'
gh pr view 123 --json mergeable --jq '.mergeable == "MERGEABLE"'
gh pr view 123 --json reviewDecision --jq '.reviewDecision == "APPROVED"'
gh pr checks 123 --json state --jq 'all(.state == "SUCCESS")'
```

## Owner and Repo Variables

GitHub CLI automatically fills `{owner}` and `{repo}` from current directory:

```bash
# Automatic (uses current repo)
gh api repos/{owner}/{repo}/pulls/123/comments

# Explicit
gh api repos/myorg/myrepo/pulls/123/comments

# Or use --repo flag
gh api --repo myorg/myrepo repos/{owner}/{repo}/pulls/123/comments
```

## jq Filtering Tips

```bash
# Select specific fields
gh api repos/{owner}/{repo}/pulls/123/comments --jq '.[] | {user: .user.login, body}'

# Filter by condition
gh api repos/{owner}/{repo}/pulls/123/reviews --jq '.[] | select(.state == "CHANGES_REQUESTED")'

# Count items
gh api repos/{owner}/{repo}/pulls/123/comments --jq 'length'

# Get first item
gh api repos/{owner}/{repo}/pulls/123/reviews --jq '.[0]'

# Sort by date
gh api repos/{owner}/{repo}/pulls/123/comments --jq 'sort_by(.created_at)'
```

## Error Handling

### Common errors and fixes:

**Not authenticated:**
```bash
gh auth login
```

**Wrong repository:**
```bash
cd /path/to/correct/repo
# or
gh pr view 123 --repo org/repo
```

**PR not found:**
```bash
gh pr list  # See available PRs
```

**Permission denied:**
```bash
# Check authentication status
gh auth status

# Re-authenticate
gh auth refresh
```

## References

- **Official docs**: https://cli.github.com/manual/
- **API docs**: https://docs.github.com/en/rest
- **jq manual**: https://stedolan.github.io/jq/manual/
