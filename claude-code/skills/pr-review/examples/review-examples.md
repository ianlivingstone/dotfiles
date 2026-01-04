# Pull Request Review Examples

Sample outputs and common scenarios for the pr-review skill.

## Example 1: Healthy PR Ready to Merge

**User request:** "Review PR #123"

**Output:**

```markdown
# PR Review: #123 - Add user authentication with JWT

## 🎯 Status Overview

**Current State:** READY
**Mergeable:** Yes
**Review Decision:** Approved

## 🚦 CI/CD Checks

### Passing ✅
- Unit Tests (https://github.com/org/repo/actions/runs/123)
- Integration Tests (https://github.com/org/repo/actions/runs/124)
- Linting (https://github.com/org/repo/actions/runs/125)
- Build (https://github.com/org/repo/actions/runs/126)
- Security Scan (https://github.com/org/repo/actions/runs/127)

### Failing ❌
None

### Pending ⏳
None

## 🚧 Merge Blockers

✅ No blockers detected - PR appears ready to merge!

## 💬 Discussion Status

### Unresolved Comments: 0

All review comments have been addressed and resolved.

### Recent Activity
- Last updated: 2 hours ago
- Latest comment: "LGTM! Great work on the test coverage." - @reviewer

## 📊 PR Health Metrics

- **Size**: 187 additions, 43 deletions (230 total)
- **Size assessment**: Ideal (200-400 LOC recommended, this PR is 230)
- **Files changed**: 8 files
- **Age**: 1 day old
- **Branch**: `feature/jwt-auth` → `main`

## ✅ Best Practices Assessment

### Strengths 💪
- Excellent PR size - easy to review thoroughly
- Comprehensive test coverage included
- Clear, detailed PR description
- Quick turnaround on review feedback
- All CI checks passing

### Improvement Opportunities 🎯
- Consider adding migration guide in docs for breaking changes
- Could split authentication and authorization into separate PRs in future

## 🎬 Recommended Next Steps

1. ✅ Merge when ready - all criteria met!
2. Monitor deployment for any issues
3. Update project documentation if needed

---

**PR URL**: https://github.com/org/repo/pull/123
**Review generated**: 2026-01-04 14:30:00 UTC
```

---

## Example 2: PR with Multiple Blockers

**User request:** "What's blocking PR #456?"

**Output:**

```markdown
# PR Review: #456 - Refactor database layer

## 🎯 Status Overview

**Current State:** BLOCKED
**Mergeable:** No - Conflicts exist
**Review Decision:** Changes Requested

## 🚦 CI/CD Checks

### Passing ✅
- Linting (https://github.com/org/repo/actions/runs/234)

### Failing ❌
- Unit Tests: 3 tests failing (https://github.com/org/repo/actions/runs/235)
  - test_user_creation: AssertionError
  - test_transaction_rollback: Timeout
  - test_connection_pool: ConnectionError
- Build: Compilation errors (https://github.com/org/repo/actions/runs/236)
  - `undefined reference to 'DatabasePool::init'`

### Pending ⏳
- Security Scan (waiting for tests to pass)

## 🚧 Merge Blockers

⚠️ **3 critical blockers must be resolved:**

1. **Merge Conflicts**
   - **Files in conflict**: `src/database/pool.rs`, `src/models/user.rs`
   - **Action needed**: Rebase on latest main and resolve conflicts
   - **Command**: `git checkout main && git pull && git checkout feature/db-refactor && git rebase main`

2. **Failing Tests**
   - **Action needed**: Fix 3 failing unit tests
   - **Details**: See test output at https://github.com/org/repo/actions/runs/235
   - **Priority**: High - tests indicate functionality issues

3. **Changes Requested by Reviewers**
   - **Reviewer**: @senior-engineer
   - **Request**: "Need to handle connection pool exhaustion gracefully"
   - **Action needed**: Implement error handling for pool exhaustion

## 💬 Discussion Status

### Unresolved Comments: 5

1. **File**: `src/database/pool.rs:45`
   - **Reviewer**: @senior-engineer
   - **Comment**: "This will panic if the pool is exhausted. We need graceful degradation here."
   - **Action**: Add proper error handling with retry logic

2. **File**: `src/database/connection.rs:89`
   - **Reviewer**: @security-lead
   - **Comment**: "Potential SQL injection vulnerability here. Use parameterized queries."
   - **Action**: **CRITICAL** - Fix security issue before merge

3. **File**: `src/models/user.rs:123`
   - **Reviewer**: @code-reviewer
   - **Comment**: "Should we add an index on this column for performance?"
   - **Action**: Discuss trade-offs and decide on indexing strategy

4. **File**: `src/database/migrations/001_init.sql:15`
   - **Reviewer**: @dba
   - **Comment**: "This migration will lock the table for ~30 minutes on production data size."
   - **Action**: Consider online schema change or batched migration

5. **File**: `README.md:67`
   - **Reviewer**: @docs-team
   - **Comment**: "Please update the database connection examples with the new API."
   - **Action**: Update documentation to reflect new connection API

### Recent Activity
- Last updated: 3 days ago
- Latest comment: "Please address the security concern before we can approve." - @security-lead

## 📊 PR Health Metrics

- **Size**: 1,247 additions, 894 deletions (2,141 total)
- **Size assessment**: ⚠️ Too Large (200-400 LOC recommended, this PR is 2,141)
- **Files changed**: 23 files
- **Age**: 12 days old
- **Branch**: `feature/db-refactor` → `main`

## ✅ Best Practices Assessment

### Strengths 💪
- Comprehensive refactoring with clear goals
- Migration scripts included

### Improvement Opportunities 🎯
- **PR is too large** - Consider breaking into smaller PRs:
  1. Database connection pool refactor
  2. Query interface changes
  3. Migration system updates
  4. Model layer changes
- **Security issue must be fixed** - SQL injection vulnerability
- **PR is stale** (12 days old) - Consider rebasing on latest main
- **Tests are failing** - Fix before requesting reviews

## 🎬 Recommended Next Steps

**Priority order:**

1. **🔴 CRITICAL**: Fix SQL injection vulnerability in `connection.rs:89`
2. **🔴 HIGH**: Resolve merge conflicts by rebasing on main
3. **🟡 MEDIUM**: Fix 3 failing unit tests
4. **🟡 MEDIUM**: Address all unresolved review comments
5. **🟢 LOW**: Consider splitting PR into smaller chunks for easier review
6. **🟢 LOW**: Update documentation per @docs-team feedback

**Commands to run:**
```bash
# 1. Rebase on latest main
git checkout main && git pull
git checkout feature/db-refactor
git rebase main

# 2. Run tests locally
cargo test  # or npm test, pytest, etc.

# 3. Request re-review after fixes
gh pr ready --undo  # mark as draft while fixing
# ... make fixes ...
gh pr ready  # mark as ready when done
gh pr comment --body "All feedback addressed, ready for re-review"
```

---

**PR URL**: https://github.com/org/repo/pull/456
**Review generated**: 2026-01-04 14:35:00 UTC
```

---

## Example 3: Draft PR Pending Review

**User request:** "Check status of my PR"

**Output:**

```markdown
# PR Review: #789 - Add dark mode support

## 🎯 Status Overview

**Current State:** DRAFT
**Mergeable:** Yes
**Review Decision:** Review Required (no reviews yet)

## 🚦 CI/CD Checks

### Passing ✅
- Linting (https://github.com/org/repo/actions/runs/345)
- Build (https://github.com/org/repo/actions/runs/346)

### Failing ❌
None

### Pending ⏳
- Unit Tests (https://github.com/org/repo/actions/runs/347)
- E2E Tests (https://github.com/org/repo/actions/runs/348)

## 🚧 Merge Blockers

⚠️ **1 blocker:**

1. **PR is in Draft Status**
   - **Action needed**: Mark PR as ready for review when complete
   - **Command**: `gh pr ready`
   - **Note**: CI checks are still running - wait for them to complete first

## 💬 Discussion Status

### Unresolved Comments: 0

No review comments yet (PR is in draft).

### Recent Activity
- Last updated: 15 minutes ago
- Latest commit: "Add dark mode toggle component"

## 📊 PR Health Metrics

- **Size**: 342 additions, 128 deletions (470 total)
- **Size assessment**: Good (200-400 LOC recommended, this PR is 470 - slightly over but acceptable)
- **Files changed**: 12 files
- **Age**: 3 hours old
- **Branch**: `feature/dark-mode` → `main`

## ✅ Best Practices Assessment

### Strengths 💪
- Reasonable PR size for the feature scope
- Quick iteration (only 3 hours old)
- CI checks running automatically

### Improvement Opportunities 🎯
- Wait for all checks to complete before marking ready
- Consider adding screenshots to PR description for UI changes
- Ensure dark mode works across all pages (test coverage)

## 🎬 Recommended Next Steps

1. ⏳ Wait for pending CI checks to complete
2. ✅ Verify all checks pass
3. 📸 Add screenshots of dark mode UI to PR description
4. ✅ Mark PR as ready: `gh pr ready`
5. 👥 Request specific reviewers if needed: `gh pr edit --add-reviewer @username`

---

**PR URL**: https://github.com/org/repo/pull/789
**Review generated**: 2026-01-04 14:40:00 UTC
```

---

## Example 4: Small PR with Minor Issues

**User request:** "Is PR #321 ready to merge?"

**Output:**

```markdown
# PR Review: #321 - Fix typo in documentation

## 🎯 Status Overview

**Current State:** PENDING REVIEW
**Mergeable:** Yes
**Review Decision:** Approved

## 🚦 CI/CD Checks

### Passing ✅
- Markdown Linting (https://github.com/org/repo/actions/runs/456)
- Spell Check (https://github.com/org/repo/actions/runs/457)

### Failing ❌
None

### Pending ⏳
None

## 🚧 Merge Blockers

✅ No blockers - PR is ready to merge!

## 💬 Discussion Status

### Unresolved Comments: 0

All comments resolved.

### Recent Activity
- Last updated: 1 hour ago
- Latest comment: "Approved! Thanks for catching this." - @maintainer

## 📊 PR Health Metrics

- **Size**: 3 additions, 3 deletions (6 total)
- **Size assessment**: Small - Ideal for quick review
- **Files changed**: 1 file
- **Age**: 2 hours old
- **Branch**: `fix/docs-typo` → `main`

## ✅ Best Practices Assessment

### Strengths 💪
- Perfect PR size for a typo fix
- Quick turnaround
- Clear, focused change
- Appropriate reviewer approved

### Improvement Opportunities 🎯
None - this is a textbook simple PR!

## 🎬 Recommended Next Steps

1. ✅ Merge now - all criteria met!
   - **Command**: `gh pr merge --squash` (or --merge/--rebase per project policy)
2. 🗑️ Delete branch after merge: `gh pr merge --delete-branch`

---

**PR URL**: https://github.com/org/repo/pull/321
**Review generated**: 2026-01-04 14:45:00 UTC
```

---

## Common Scenarios Quick Reference

### Scenario: "What's blocking my PR?"
Focus output on:
- Failing checks with links
- Unresolved comments (most critical first)
- Merge conflicts
- Review status

### Scenario: "Is this PR ready to merge?"
Provide clear YES/NO answer:
- ✅ Yes + green light to merge
- ❌ No + specific blockers to fix

### Scenario: "Review this PR"
Full comprehensive review including:
- All status sections
- Best practices assessment
- Health metrics
- Next steps

### Scenario: "Check PR #123"
Same as full review, fetch by number

### Scenario: "What do reviewers think about my PR?"
Focus on:
- Review comments and status
- Unresolved discussions
- Approval status
- Recent feedback

---
---

**Part of pr-review skill** - See [fix-examples.md](fix-examples.md) for fix workflow examples.

**Last Updated:** 2026-01-04
