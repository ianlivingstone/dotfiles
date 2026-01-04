# PR Fix Workflow

Step-by-step workflow for automatically fixing PR review feedback, failing tests, and merge conflicts.

## When to Use

Use this workflow when the user wants to:
- Fix review comments
- Address PR feedback
- Fix failing tests
- Resolve merge conflicts
- Implement suggested changes

**NOT** for review-only (see review-workflow.md)

## Prerequisites

1. GitHub CLI (`gh`) installed and authenticated
2. In the repository with the PR
3. **User confirmation before making changes**

## Fix Workflow Overview

```
1. Fetch and analyze PR feedback
2. Prioritize issues (blockers first)
3. Confirm scope with user
4. Make changes systematically
5. Verify changes resolve feedback
6. Summarize what was fixed
```

## Step 1: Fetch Detailed Feedback

Gather comprehensive context for making fixes. GitHub has THREE types of comments (see [../reference/comment-types.md](../reference/comment-types.md)):

**Fetch ALL comment types:**

```bash
# 1. Get PR diff
gh pr diff <pr>

# 2. Issue comments (general discussion)
gh api repos/{owner}/{repo}/issues/<pr>/comments

# 3. Review comments (inline code)
gh api repos/{owner}/{repo}/pulls/<pr>/comments

# 4. Review summaries (approve/request changes)
gh api repos/{owner}/{repo}/pulls/<pr>/reviews

# 5. Review threads (resolution status)
gh pr view <pr> --json reviewThreads

# 6. Check out PR branch
gh pr checkout <pr>

# 7. Get files changed
gh pr view <pr> --json files
```

**Filter**: Exclude resolved threads, outdated comments, and bot comments.

## Step 2: Analyze and Prioritize

Categorize by priority with specific criteria:

### 🔴 CRITICAL (Fix immediately, halt other work)
- **Security**: SQL injection, XSS, auth bypass, credential exposure, path traversal
- **Data integrity**: Data loss, corruption, race conditions, improper transactions
- **CI blockers**: Failing tests prevent merge, build failures, deployment blockers

Examples:
- "This allows SQL injection via username parameter"
- "Race condition causes duplicate charges"
- "Build failing due to missing dependency"

### 🟡 HIGH (Fix before merge)
- **Logic errors**: Incorrect calculations, wrong conditions, flawed algorithms
- **Unhandled exceptions**: Missing try-catch in critical paths, no error responses
- **Breaking changes**: API changes without migration, incompatible updates

Examples:
- "Function returns wrong result when input is negative"
- "No error handling when database is down"
- "API response format changed without versioning"

### 🟢 MEDIUM (Fix preferred but negotiable)
- **Code style**: Violations of style guide, inconsistent patterns
- **Test coverage**: Missing tests for new code, inadequate edge case coverage
- **Documentation**: Outdated/missing docs, unclear comments

Examples:
- "This function doesn't follow naming convention"
- "Missing test case for null input"
- "README doesn't document new endpoint"

### ⚪ LOW (Nice to have)
- **Naming**: Variable/function naming improvements (without functional impact)
- **Formatting**: Whitespace, line length, bracket style
- **Optimizations**: Performance improvements (if not blocking or critical)

Examples:
- "Consider renaming 'data' to 'userData' for clarity"
- "Inconsistent indentation"
- "Could cache this for minor performance gain"

## Step 3: Confirm Scope with User

**CRITICAL**: Present plan before making changes:

```markdown
## Fixes Planned

I found X review comments:

### Critical (2)
1. [File:Line] Security: SQL injection
   - Fix: Use parameterized queries

### High Priority (3)
2. [File:Line] Bug: Null pointer exception
   - Fix: Add null check
3. [File:Line] Logic error: Wrong calculation
   - Fix: Correct formula

### Medium (2)
4. [File:Line] Code style: Inconsistent naming
   - Fix: Rename for consistency
5. [File:Line] Documentation: Outdated examples
   - Fix: Update examples

Would you like me to:
A) Fix all issues (1-5)
B) Fix only critical/high priority (1-3)
C) Let me choose specific issues to skip
D) Review and discuss first (no changes yet)
```

**Wait for user confirmation.**

**If user chooses C (selective fixing):**
```markdown
Which issues should I skip? (comma-separated numbers or "none")
Example: "4,5" to skip issues 4 and 5
Example: "none" to fix all

I'll fix the remaining issues and provide a summary at the end.
```

**Benefits of skip option:**
- Allows user to defer low-priority issues
- Can skip issues that need more discussion
- Can skip issues blocked by other work
- Maintains momentum on critical fixes

## Step 4: Make Changes Systematically

For each issue:

### a. Read Code
- Use Read tool on relevant files
- Use Grep to find related code

### b. Understand Context

**Read surrounding code:**
```bash
# Read the entire file
Read tool: path/to/file.js

# Read related files
Read tool: path/to/related-module.js
```

**Check for similar patterns:**
```bash
# Find similar function names
Grep tool: "function.*User" (pattern) *.js (glob)

# Find all uses of a variable
Grep tool: "userAccount" **/*.js

# Find similar error handling
Grep tool: "try.*catch" src/**/*.js
```

**Review test expectations:**
```bash
# Read the test file
Read tool: tests/auth.test.js

# Find all related tests
Grep tool: "describe.*Auth" tests/**/*.js

# Check test mocks and fixtures
Read tool: tests/__mocks__/user.js
```

**Consider side effects:**
```bash
# Find all callers of this function
Grep tool: "authenticateUser\(" src/**/*.js

# Check for event listeners
Grep tool: "addEventListener.*click" src/**/*.js

# Find database queries in area
Grep tool: "SELECT.*FROM users" src/**/*.js
```

**Key questions to answer:**
- How is this function called? (find callers)
- What does it depend on? (read imports)
- What depends on it? (find references)
- Are there tests? (check test files)
- What's the expected behavior? (read test assertions)
- Could this break other code? (find usages)

### c. Implement Fix
- Use Edit tool for precise changes
- Make minimal changes
- Preserve existing style
- Add comments if needed

### d. Verify Fix
```bash
npm test path/to/test
npm run lint
npm run build
```

Iterate until passing.

## Step 5: Common Fix Types

### Merge Conflicts

```bash
git fetch origin
git rebase origin/main

# If conflicts:
# Read conflicted file
# Edit to resolve (remove markers)
# Continue rebase
git rebase --continue

# Force push (PR branch ONLY!)
git push --force-with-lease
```

**⚠️ WARNING**: Never force-push to main/master!

### Failing Tests

```bash
# Run failing test
npm test -- --testNamePattern="test name"

# Read test and implementation
# Fix implementation
# Verify test passes
```

### Code Review Comments

Example: "Function does too much"

Steps:
1. Read function
2. Identify logical sections
3. Extract helper functions
4. Update to use helpers
5. Verify tests pass
6. Add documentation

### Documentation

```bash
# Read current docs
Read tool: README.md

# Update based on changes
Edit tool: update sections

# Check other docs
Glob tool: **/*.md
```

## Step 6: Final Verification

```bash
npm test      # All tests
npm run lint  # Linting
npm run build # Build (if applicable)
git status    # Check changes
git diff      # Review changes
```

## Step 7: Summarize Changes

```markdown
## PR Feedback Fixes Applied

### Fixed (5 issues)

✅ Security: SQL injection (file.js:123)
✅ Bug: Null pointer (file.js:234)
✅ Tests: Fixed failing auth test
✅ Documentation: Updated API docs
✅ Style: Extracted large function

### Verification
- All tests passing ✅
- Linting clean ✅
- Build successful ✅

### Next Steps
1. Review: git diff
2. Push: git push
3. Notify: gh pr comment
```

## Step 8: Add PR Comment (Optional)

```bash
gh pr comment <pr> --body "All feedback addressed. Ready for re-review."
```

## Step 9: Create Audit Log

**Purpose**: Track what was changed, why, and results for debugging and accountability.

Create a detailed log of the fix session:

```markdown
## Fix Session Audit Log
**PR**: #123 - Add user authentication
**Date**: 2026-01-04
**Requested by**: @reviewer
**Session duration**: 45 minutes

### Issues Addressed (5 total)

#### Issue 1: SQL Injection (CRITICAL)
- **Location**: src/auth.js:123
- **Comment by**: @security-reviewer
- **Problem**: Direct string concatenation in SQL query
- **Fix approach**: Replaced with parameterized query
- **Files changed**:
  - src/auth.js (1 change)
- **Tests affected**: tests/auth.test.js
- **Verification**:
  - Tests passed ✅
  - Security scan passed ✅
- **Attempts**: 1/3
- **Result**: SUCCESS

#### Issue 2: Missing Error Handling (HIGH)
- **Location**: src/api/users.js:234
- **Comment by**: @lead-reviewer
- **Problem**: No try-catch for database operations
- **Fix approach**: Added try-catch with proper error response
- **Files changed**:
  - src/api/users.js (1 change)
- **Tests affected**: tests/api/users.test.js
- **Verification**:
  - Tests passed ✅ (after 2 attempts)
  - Linting passed ✅
- **Attempts**: 2/3
- **Result**: SUCCESS
- **Notes**: First attempt failed due to missing null check

#### Issue 3: Outdated Documentation (MEDIUM)
- **Location**: README.md:45-60
- **Comment by**: @reviewer
- **Problem**: API examples showed old endpoint format
- **Fix approach**: Updated examples to new format
- **Files changed**:
  - README.md (1 change)
- **Verification**: Manual review ✅
- **Attempts**: 1/3
- **Result**: SUCCESS

#### Issue 4: Inconsistent Naming (LOW)
- **Location**: src/utils/helpers.js:89
- **Comment by**: @reviewer
- **Problem**: Function named 'getData' was too generic
- **Fix approach**: Renamed to 'getUserAccountData'
- **Files changed**:
  - src/utils/helpers.js (1 change)
  - src/components/Profile.js (3 references updated)
- **Tests affected**: tests/utils/helpers.test.js
- **Verification**: Tests passed ✅
- **Attempts**: 1/3
- **Result**: SUCCESS

#### Issue 5: Merge Conflict (BLOCKER)
- **Location**: package.json:15-20
- **Problem**: Conflict with main branch
- **Fix approach**: Rebased and resolved keeping both dependencies
- **Files changed**:
  - package.json (resolved conflict)
- **Verification**:
  - npm install passed ✅
  - Tests passed ✅
- **Attempts**: 1/3
- **Result**: SUCCESS

### Summary Statistics

**Priority breakdown:**
- 🔴 Critical: 1 (100% fixed)
- 🟡 High: 1 (100% fixed)
- 🟢 Medium: 1 (100% fixed)
- ⚪ Low: 1 (100% fixed)
- 🚧 Blocker: 1 (100% fixed)

**Efficiency:**
- Total issues: 5
- Fixed: 5 (100%)
- Average attempts: 1.2/3
- First-attempt success rate: 80%

**Files modified:** 5
**Test files updated:** 2
**Documentation updated:** 1

**Verification results:**
- All tests passing: ✅
- Linting clean: ✅
- Build successful: ✅
- No new warnings: ✅

### Lessons Learned

**What worked well:**
- Reading surrounding code before fixes prevented issues
- Test-driven approach caught error early (Issue 2)
- Systematic priority ordering kept focus on critical issues

**What could improve:**
- Issue 2 needed null check - should have caught in initial review
- Could have batched related changes for efficiency

### Recommendations for Next Time

1. For similar projects, add null checks when adding error handling
2. Check for related references before renaming (helped with Issue 4)
3. Run security scan immediately after fixing security issues
```

**Benefits of audit logging:**
- **Debugging**: If tests fail later, know exactly what changed
- **Learning**: Track which approaches work vs which need iteration
- **Accountability**: Clear record of what was done and why
- **Efficiency**: Identify patterns to improve future fix sessions
- **Communication**: Can share detailed log with team if needed

**When to use:**
- Complex fix sessions with multiple issues
- Security-related fixes (always log these)
- When fixes required multiple attempts
- For future reference and knowledge sharing

## Safety Rules

See [safety-guidelines.md](safety-guidelines.md) for complete rules.

**Quick reference:**

**ALWAYS:**
- Confirm with user first
- Read code before modifying
- Run tests after changes
- Make minimal changes

**NEVER:**
- Skip testing
- Modify without understanding
- Force push to main/master
- Disable linting/tests
- Make unrelated changes

**ASK USER if:**
- Multiple approaches exist
- Side effects possible
- Tests missing
- Breaking change needed

## References

- [Comment Types](../reference/comment-types.md)
- [Best Practices](../reference/best-practices.md)
- [Safety Guidelines](safety-guidelines.md)
- [Fix Examples](../examples/fix-examples.md)
