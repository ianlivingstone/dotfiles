# Safety Guidelines for PR Fixes

Critical safety rules when making code changes to fix PR feedback.

## User Confirmation Required

**MUST get user confirmation before making ANY code changes.**

Present a plan showing:
- What issues you found
- What changes you'll make
- Priority/severity of each issue

Wait for explicit user approval before proceeding.

## Code Modification Rules

### MUST (Required)

- **MUST read code before modifying**
  - Never edit files you haven't read
  - Understand context and intent first

- **MUST make minimal changes**
  - Only change what's necessary to fix the issue
  - Don't refactor unrelated code
  - Don't add "improvements" beyond the fix

- **MUST run tests after each change**
  - Run relevant tests immediately after fix
  - Verify tests pass before moving to next issue
  - Never batch changes without testing

- **MUST verify changes resolve feedback**
  - Confirm fix addresses the original concern
  - Test edge cases mentioned in feedback
  - Document what was fixed

- **MUST preserve existing style**
  - Match surrounding code style
  - Use project's existing patterns
  - Don't impose personal preferences

- **MUST keep user informed**
  - Show progress as you work
  - Explain reasoning for changes
  - Report verification results

### MUST NOT (Prohibited)

- **MUST NOT make changes without user confirmation**
  - Always present plan first
  - Wait for explicit approval
  - If unsure, ask

- **MUST NOT skip testing to pass checks**
  - Never disable tests
  - Never comment out failing assertions
  - Never skip linting requirements
  - Fix root cause, don't hide failures

- **MUST NOT modify code without understanding it**
  - If code is unclear, ask user for clarification
  - Read surrounding context
  - Check related code and tests

- **MUST NOT force push to protected branches**
  - Only use `git push --force-with-lease` on PR branches
  - NEVER force push to main, master, develop, or other protected branches
  - Verify current branch before force pushing

- **MUST NOT disable linting or security checks**
  - Fix issues, don't silence warnings
  - Never add eslint-disable comments without user approval
  - Never skip security scans

- **MUST NOT make unrelated improvements**
  - Stay focused on fixing reported issues
  - Don't add features not requested
  - Don't refactor code beyond the fix
  - Don't "clean up" surrounding code

### SHOULD (Recommended)

- **SHOULD verify fix approach with user if ambiguous**
  - Multiple valid solutions → ask user to choose
  - Architectural changes → discuss first
  - Performance trade-offs → explain options

- **SHOULD add comments explaining complex fixes**
  - If fix is non-obvious, add explanation
  - Document why approach was chosen
  - Link to issue/discussion if applicable

- **SHOULD test edge cases**
  - Test boundary conditions
  - Test error paths
  - Test with invalid input

- **SHOULD maintain test coverage**
  - Add tests for new code paths
  - Update tests when logic changes
  - Don't reduce coverage percentage

## Security Considerations

### File Type Warnings

**MUST warn user before modifying these file types:**
- `.env` files (may contain secrets)
- `config/*.yml` (may have credentials)
- `secrets.json` or similar (obvious secrets)
- SSH keys (`id_rsa`, `id_ed25519`, etc.)
- Certificate files (`.pem`, `.key`, `.crt`)

**Example warning:**
```
⚠️ Warning: This fix modifies a configuration file that may contain secrets.
Please review changes carefully before pushing.
```

### Force Push Safety

When using `git push --force-with-lease`:

**MUST verify:**
1. Current branch is the PR branch (not main/master)
2. You're not on a protected branch
3. Changes are intentional and reviewed

**Example check:**
```bash
# Verify branch before force push
current_branch=$(git branch --show-current)
if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
    echo "❌ Cannot force-push to $current_branch"
    exit 1
fi
git push --force-with-lease
```

### Input Validation

When fixing code that handles user input:

- **MUST verify input validation exists**
- **MUST check for injection vulnerabilities** (SQL, XSS, command injection)
- **MUST validate file paths** (prevent path traversal)
- **MUST check for rate limiting** (if applicable)

## Test Verification

### After Each Fix

**MUST run:**
1. Relevant unit tests for modified code
2. Integration tests if dependencies changed
3. Linting (eslint, pylint, etc.)
4. Type checking (TypeScript, mypy, etc.)
5. Build process (if applicable)

### Before Completing

**MUST run full verification:**
```bash
# Full test suite
npm test  # or pytest, cargo test, etc.

# Full linting
npm run lint

# Build (if applicable)
npm run build

# Check git status
git status

# Review all changes
git diff
```

### If Tests Fail

**MUST:**
1. Review the error message carefully
2. Identify root cause
3. Fix the root cause (don't mask the failure)
4. Re-run tests to verify
5. If still failing after reasonable attempts, report to user

**MUST NOT:**
1. Skip the test
2. Comment out assertions
3. Disable the test
4. Change test to match wrong behavior
5. Commit failing code

## When to Ask User

**MUST ask user if:**

### Ambiguity
- Multiple valid approaches exist
- Requirements are unclear
- Feedback is contradictory
- Best practice conflicts with existing pattern

### Risk
- Change might have side effects
- Breaking change might be needed
- Performance impact unclear
- Security implications unknown

### Missing Context
- Tests don't exist for the area
- Documentation is incomplete
- Code intent is unclear
- Related systems unknown

### Architectural
- Major refactoring suggested
- Design pattern change needed
- Dependency addition required
- Database schema change implied

## Error Handling

### When Fix Doesn't Work

If your fix doesn't resolve the issue:

1. **Review the feedback again**
   - Re-read reviewer's comment
   - Check if you understood correctly
   - Look for additional context

2. **Check test output**
   - Read error messages carefully
   - Look for root cause
   - Check for related failures

3. **Ask user for guidance**
   ```
   I attempted to fix [issue] by [approach], but [result].
   The test shows: [error message]

   Would you like me to:
   A) Try a different approach
   B) Investigate further
   C) Discuss with you before proceeding
   ```

4. **Don't repeatedly try random fixes**
   - If first 2-3 attempts fail, ask user
   - Don't waste time guessing
   - Explain what you tried and why it didn't work

### When Approach is Wrong

If user indicates your approach is incorrect:

1. **Acknowledge and reset**
   - Revert changes if needed
   - Understand what went wrong
   - Ask clarifying questions

2. **Discuss alternative**
   - Ask user to explain preferred approach
   - Confirm understanding before implementing
   - Implement with new approach

## Examples

### Good: User Confirmation

```
I found 3 issues to fix:

1. SQL injection in auth.js:45 (CRITICAL)
   - Fix: Use parameterized queries

2. Missing error handling in api.js:123 (HIGH)
   - Fix: Add try-catch with proper error response

3. Outdated docs in README.md (MEDIUM)
   - Fix: Update API examples

Would you like me to fix all of these?
```

**Waits for user response before proceeding.**

### Bad: No Confirmation

```
Fixing all issues...
[Makes changes without asking]
```

**Violates MUST get confirmation rule.**

### Good: Asking for Clarification

```
The reviewer says "improve error handling" but there are two approaches:

A) Add try-catch with generic error message
B) Add specific error codes for each failure type

Which approach would you prefer?
```

### Bad: Guessing

```
I'll add try-catch blocks everywhere to improve error handling.
[Makes extensive changes without asking]
```

**Violates MUST NOT make changes without understanding rule.**

## Rate Limiting and Retry Behavior

**Purpose**: Prevent infinite loops and wasted effort when fixes don't work.

### MUST limit fix attempts per issue

- **Maximum 3 fix iterations** for any single issue
- After 2 failed attempts, MUST ask user for guidance
- Track attempts to prevent infinite retry loops

**Example template after 2 failures:**

```markdown
I've tried fixing [issue] twice, but [test/check] is still failing:

Attempt 1: [what was tried]
Result: [what failed]

Attempt 2: [what was tried]
Result: [what failed]

The issue may require:
A) A different approach - let me try [alternative]
B) More context - can you provide [information needed]?
C) Manual intervention - this might need human review

What would you like me to do?
```

### MUST prevent infinite loops

**File edit tracking:**
- If same file edited **>5 times** in one session, MUST pause and ask:
  ```
  I've edited [file] 5 times. Before continuing, would you like to:
  - Review the changes so far (git diff)
  - Try a different approach
  - Take over manually
  ```

**Test failure tracking:**
- If tests fail **>3 times consecutively** with different fixes, MUST halt and report:
  ```
  Tests have failed 3 times with different approaches:
  1. [approach 1] - failed because [reason]
  2. [approach 2] - failed because [reason]
  3. [approach 3] - failed because [reason]

  This suggests a deeper issue. Recommend:
  - Review test expectations
  - Check for environmental issues
  - Manual debugging session
  ```

**Build failure tracking:**
- If build fails **>2 times consecutively**, MUST stop and ask for help:
  ```
  Build is still failing after 2 fix attempts. This may indicate:
  - Dependency issue
  - Configuration problem
  - Type system incompatibility

  Should we investigate the root cause together?
  ```

### SHOULD provide fix iteration status

When making multiple fix attempts, keep user informed:

```markdown
Fixing issue 1/5: SQL injection in auth.js:123
Attempt 1/3: Adding parameterized query...
✅ Fix applied, running tests...
✅ Tests passed!

Fixing issue 2/5: Missing error handling in api.js:234
Attempt 1/3: Adding try-catch...
❌ Tests failed: TypeError in related function
Attempt 2/3: Adding null check before try-catch...
✅ Tests passed!
```

### MUST NOT

- **MUST NOT** retry indefinitely without user input
- **MUST NOT** make increasingly drastic changes when simple fixes fail
- **MUST NOT** skip verification to "get past" a persistent failure
- **MUST NOT** disable tests or linting to make checks pass

### Rationale

**Why these limits?**

1. **3 iterations**: Research shows most fixable issues resolve in 1-2 attempts. After 3, diminishing returns.
2. **5 edits per file**: Prevents thrashing. More than 5 edits suggests approach is wrong.
3. **3 test failures**: Pattern recognition. Same test failing 3 times = need different strategy.

**Alternative**: If hitting limits frequently, root cause may be:
- Inadequate context about codebase
- Missing understanding of test expectations
- Insufficient information in review comments
- Architectural issue requiring design discussion

## Summary

The cardinal rules for safe PR fixes:

1. **Get confirmation first**
   - Present plan with priorities
   - Wait for explicit approval
   - Offer options when multiple approaches exist
   - Example: "Would you like me to: A) Fix all, B) Fix critical only, C) Review first?"

2. **Read before modifying**
   - Use Read tool on target files
   - Use Grep to find related code
   - Check test files for expectations
   - Understand context and intent
   - Example: Read auth.js, grep for "authenticate", check tests/auth.test.js

3. **Test after every change**
   - Run relevant tests immediately
   - Verify tests pass before next change
   - Don't batch multiple changes without testing
   - Example: `npm test path/to/test.js` after each fix

4. **Never skip tests to pass checks**
   - Fix root cause, don't hide failures
   - Don't disable tests or eslint
   - Don't comment out failing assertions
   - Don't skip security scans
   - If stuck after 2-3 attempts, ask user for guidance

5. **Ask when unsure**
   - Multiple valid approaches? Ask which to use
   - Complex fix with side effects? Confirm approach
   - Test missing? Ask if should add
   - Breaking change needed? Discuss first
   - Example: "The fix could use approach A (faster) or B (safer). Which do you prefer?"

### Quick Decision Tree

**Before starting:**
- [ ] User approved the plan?
- [ ] Read all relevant code?
- [ ] Understand what needs fixing?

**For each fix:**
- [ ] Made minimal change?
- [ ] Ran tests and verified pass?
- [ ] No unrelated changes?

**After all fixes:**
- [ ] All tests passing?
- [ ] Linting clean?
- [ ] Build successful?
- [ ] Summarized changes for user?

**When in doubt at ANY step: Ask the user.**
