# Pull Request Best Practices

Research-backed guidelines for creating and reviewing high-quality pull requests.

## Executive Summary

A merge-ready PR should be:
- **Small**: 200-400 lines of code (LOC) maximum
- **Focused**: Single purpose, one feature or fix
- **Tested**: Comprehensive test coverage
- **Documented**: Clear description and code comments
- **Approved**: At least one approval from qualified reviewer
- **Passing**: All CI/CD checks green
- **Conflict-free**: No merge conflicts with target branch

## PR Size Guidelines

### Recommended Sizes

| Size | LOC | Review Time | Defect Rate | Notes |
|------|-----|-------------|-------------|-------|
| **Ideal** | 100-200 | 15-30 min | Lowest | Easiest to review thoroughly |
| **Good** | 200-400 | 30-60 min | Low | Still manageable |
| **Large** | 400-1000 | 1-3 hours | Higher | Consider splitting |
| **Too Large** | 1000+ | 3+ hours | Highest | Definitely split |

### Why Size Matters

**LinearB's 2025 study found:**
- Cycle time doubles when comparing 200 LOC PRs to 100 LOC PRs
- Idle time increases significantly with larger PRs
- Reviewer fatigue sets in after 400 lines
- Defect detection drops dramatically over 400 lines

**Action:** If your PR exceeds 400 LOC, consider breaking it into smaller, logical chunks.

## Core Checklist Categories

### 1. Code Functionality and Quality

**MUST verify:**
- [ ] Code works as expected in happy path
- [ ] Edge cases are handled correctly
- [ ] Error conditions are handled gracefully
- [ ] No obvious bugs or logic errors
- [ ] Performance is acceptable
- [ ] Security vulnerabilities are addressed

**Questions to ask:**
- Does the code handle all user inputs safely?
- What happens with invalid/unexpected data?
- Are there race conditions or concurrency issues?
- Does it work across different environments?

### 2. Testing Requirements

**MUST include:**
- [ ] Unit tests for new functions/methods
- [ ] Integration tests for new features
- [ ] Tests for edge cases and error conditions
- [ ] Test coverage meets project standards (typically 80%+)
- [ ] All tests pass locally and in CI

**Testing pyramid:**
```
       /\
      /E2E\        Few (slow, expensive)
     /------\
    /  INT   \     Some (medium speed/cost)
   /----------\
  /    UNIT    \   Many (fast, cheap)
 /--------------\
```

**Why testing matters:**
- Prevents regressions
- Documents expected behavior
- Enables confident refactoring
- Catches bugs before production

### 3. Code Style and Standards

**MUST follow:**
- [ ] Project's style guide
- [ ] Consistent naming conventions
- [ ] Proper code formatting (use auto-formatters)
- [ ] Linting rules pass
- [ ] No console.log, debugger, or debug code

**Automation is key:**
- Use Prettier, Black, rustfmt, or similar for formatting
- Use ESLint, pylint, clippy for linting
- Configure pre-commit hooks to enforce automatically
- Don't waste reviewer time on style nits

### 4. Documentation

**MUST document:**
- [ ] Public APIs with docstrings/comments
- [ ] Complex algorithms with explanation
- [ ] Why decisions were made (not just what)
- [ ] PR description explains the change
- [ ] README updated if behavior changes
- [ ] CHANGELOG entry (if project uses one)

**PR Description Template:**
```markdown
## What
Brief description of what changed (1-2 sentences)

## Why
Why this change is necessary

## How
How the change works (technical approach)

## Testing
How you tested this change

## Screenshots (if UI changes)
Before / After

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or breaking changes documented)
```

### 5. Branch Management

**MUST ensure:**
- [ ] Branch is up-to-date with target branch (main/master)
- [ ] No merge conflicts
- [ ] Based on latest version of codebase
- [ ] Clean commit history (squash if needed)
- [ ] Descriptive commit messages

**Keeping branches current:**
```bash
# Before opening PR
git checkout main
git pull
git checkout feature-branch
git rebase main  # or merge main, depending on project policy

# After reviews, before merge
git checkout main
git pull
git checkout feature-branch
git rebase main
```

### 6. Review Process

**Review best practices:**
- [ ] Start reviewing within 2 hours (respect author's time)
- [ ] Test the code yourself (checkout branch locally)
- [ ] Look for architectural issues first, style issues last
- [ ] Comment on good things too (positive feedback matters)
- [ ] Be specific and actionable in feedback
- [ ] Don't request changes for preference (only for issues)

**Before merging:**
- [ ] All comments addressed or discussed
- [ ] At least one approval from qualified reviewer
- [ ] Author has resolved all conversations
- [ ] No outstanding change requests

### 7. CI/CD Checks

**Required checks (typical):**
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Linting passes
- [ ] Build succeeds
- [ ] Code coverage meets threshold
- [ ] Security scanning passes (if configured)
- [ ] Performance tests pass (if applicable)

**If checks fail:**
1. Don't merge (obvious, but important)
2. Investigate the failure
3. Fix the root cause
4. Don't disable checks or skip them
5. If check is flaky, fix the check

## Communication and Collaboration

### PR Description Best Practices

**DO:**
- Write for the reviewer (set them up for success)
- Explain the "why" not just the "what"
- Include testing steps
- Link related issues/PRs
- Add screenshots for UI changes
- Highlight tricky parts that need extra attention

**DON'T:**
- Leave description empty
- Just copy the commit message
- Assume reviewer has context
- Use jargon without explanation

### Responding to Reviews

**DO:**
- Respond to every comment (even if just "Done")
- Mark conversations as resolved when addressed
- Ask clarifying questions if feedback is unclear
- Thank reviewers for their time
- Explain your reasoning if you disagree

**DON'T:**
- Get defensive about feedback
- Ignore comments
- Make changes without responding
- Merge before addressing all feedback

## Common Anti-Patterns to Avoid

### 1. The "Kitchen Sink" PR
**Problem:** Includes multiple unrelated changes
**Solution:** Split into focused PRs, one per feature/fix

### 2. The "Silent" PR
**Problem:** No description, no context, no explanation
**Solution:** Write thorough PR description

### 3. The "WIP Forever" PR
**Problem:** Stays in draft/WIP for weeks
**Solution:** Complete work before opening, or use draft PRs correctly

### 4. The "Merge and Run" PR
**Problem:** Author merges without waiting for reviews
**Solution:** Wait for approval, respect review process

### 5. The "Commented Out Code" PR
**Problem:** Includes dead code, TODOs, debug statements
**Solution:** Clean up before submitting

## Quick Reference: Is My PR Ready to Merge?

```
✅ YES if ALL of these are true:
- All CI checks passing (green)
- At least 1 approval from qualified reviewer
- No unresolved comments or change requests
- No merge conflicts
- Code is tested (tests included and passing)
- Documentation updated (if needed)
- Branch is up-to-date with target
- PR is marked as ready (not draft)

❌ NO if ANY of these are true:
- Any CI check failing (red)
- Change requests outstanding
- Unresolved comments exist
- Merge conflicts present
- No reviewer approval
- PR still in draft status
- Tests missing or failing
- Breaking changes not discussed/approved
```

## Sources and Further Reading

This guide synthesizes best practices from:

- [Best Practices for Reviewing Pull Requests in GitHub](https://rewind.com/blog/best-practices-for-reviewing-pull-requests-in-github/)
- [GitHub Pull Request Review Guide](https://github.com/mawrkus/pull-request-review-guide)
- [GitHub Docs: Helping others review your changes](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/getting-started/helping-others-review-your-changes)
- [How to review code effectively: A GitHub staff engineer's philosophy](https://github.blog/developer-skills/github/how-to-review-code-effectively-a-github-staff-engineers-philosophy/)
- [Microsoft Engineering Playbook: Pull Requests](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/pull-requests/)
- [Essential Pull Request Checklist: GitHub Best Practices](https://www.pullchecklist.com/posts/pull-request-checklist-github)
- [Speeding Up Merge Time: Checklist for Effective Pull Request](https://boradesanket13.medium.com/the-anatomy-of-a-perfect-pull-request-40def4d72cfe)
- [A complete guide to code reviews | Swarmia](https://www.swarmia.com/blog/a-complete-guide-to-code-reviews/)

---

**Last Updated:** 2026-01-04
**Research Period:** 2024-2026
