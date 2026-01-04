# Commit Workflow Analysis & Improvement Plan

**Date:** 2026-01-04
**Status:** Analysis Complete
**Priority:** HIGH - Affects core workflow reliability

## Problem Statement

The `/commit` slash command frequently hangs when Claude runs it as a background task, requiring manual intervention or cancellation. This occurred during the implementation plan commit, where multiple attempts failed with exit code 137 (SIGKILL) before succeeding with a manual foreground commit.

## Root Cause Analysis

### Issue 1: GPG Passphrase Handling Mismatch

**The Problem:**
- Line 71: `test_gpg_signing()` uses `--pinentry-mode loopback --batch --no-tty`
- Line 265: Actual commit uses plain `git commit -F "$temp_file"` without these flags
- The test may pass (passphrase cached), but actual commit can still try to launch pinentry
- In background mode, pinentry can't render → process hangs → eventually killed

**Why This Happens:**
```bash
# Test (line 71) - Forces non-interactive mode
echo "test" | gpg --sign --local-user "$signing_key" --batch --no-tty --pinentry-mode loopback -o /dev/null

# Actual commit (line 265) - May try to launch pinentry
git commit -F "$temp_file"  # Uses default Git/GPG settings
```

The test and the actual operation use different GPG invocation modes.

### Issue 2: No Background Execution Detection

**The Problem:**
- Script doesn't detect if it's running in background (no TTY)
- No early failure when passphrase prompt would be needed but can't be shown
- Claude Code treats it like any Bash command and runs in background
- Hangs indefinitely waiting for input that can never come

**Detection Missing:**
```bash
# Script should check:
if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    # Running without TTY - can't prompt for passphrase
    # Should fail early with clear instructions
fi
```

### Issue 3: Workflow Complexity

**Current Workflow (4-5 Bash invocations):**
1. `~/.claude/commands/commit.sh` - Display context
2. Generate filename via `commit.sh generate-filename`
3. Write commit message to file with `cat > $FILE <<'EOF'`
4. `~/.claude/commands/commit.sh commit "$FILE"` - Actual commit
5. (Sometimes) Cleanup temp file

**Problems:**
- Too many steps increases chance of error
- Each step is a potential background task
- Claude may run steps in parallel (wrong!)
- Context gets lost between steps

### Issue 4: Skill Documentation Ambiguity

**The commit.md skill doesn't specify:**
- ❌ That commit must run in foreground, not background
- ❌ What timeout to use (commits can take 10-30s with GPG)
- ❌ How to handle GPG agent failures gracefully
- ❌ When to fail fast vs retry
- ⚠️  Workflow could be simpler

## Measurement of Impact

**Before Fix (Commit Attempts):**
- Attempt 1: Background task hung indefinitely
- Attempt 2: Interrupted by user after timeout
- Attempt 3: Exit code 137 (SIGKILL)
- Attempt 4: Manual foreground commit succeeded

**Impact:**
- 75% failure rate (3/4 attempts failed)
- ~5 minutes wasted per failed attempt
- User frustration ("wtf is going on?")
- Requires manual intervention every time

## Improvement Recommendations

### HIGH Priority - Fix Background Execution

#### Option A: Detect and Fail Early (Safest)
Add background detection at script start:

```bash
# Near top of commit.sh, after set -euo pipefail
check_interactive_mode() {
    # Check if stdin/stdout are TTYs
    if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        echo -e "${RED}❌ Error: Commit requires interactive terminal${NC}" >&2
        echo "" >&2
        echo "This script cannot run in background because GPG signing may need your passphrase." >&2
        echo "" >&2
        echo "Fix: Run commit in foreground by directly invoking:" >&2
        echo "  git commit -m \"Your message\"" >&2
        echo "" >&2
        exit 1
    fi
}

# Call early in main() and create_commit()
check_interactive_mode
```

**Pros:**
- Fails immediately with clear error message
- Prevents hung processes
- Guides user to working solution

**Cons:**
- Breaks current usage if called from pipes/automation

#### Option B: Force Git to Fail Fast on Missing Passphrase
Configure git commit to never wait for passphrase:

```bash
create_commit() {
    # ... existing code ...

    # For GPG commits, force non-interactive mode
    if is_gpg_signing_required; then
        # Export GPG_TTY if available
        if [[ -t 0 ]]; then
            export GPG_TTY=$(tty)
        fi

        # Configure git to fail fast if GPG can't sign
        git -c "gpg.program=$(which gpg) --batch --no-tty --pinentry-mode error" \
            commit -F "$temp_file"
    else
        git commit -F "$temp_file"
    fi
}
```

**Pros:**
- Commits fail immediately instead of hanging
- Works in both background and foreground
- User gets clear error quickly

**Cons:**
- Requires GPG 2.1+ for `--pinentry-mode error`
- May need fallback for older GPG versions

### HIGH Priority - Simplify Workflow

#### Recommendation: One-Shot Commit Function

Reduce from 4-5 steps to 1-2 steps:

**In commit.sh, add:**
```bash
# New function: single-shot commit with inline message
commit_direct() {
    local commit_message="${1:-}"

    if [[ -z "$commit_message" ]]; then
        echo -e "${RED}❌ Error: No commit message provided${NC}" >&2
        exit 1
    fi

    # Validate state
    if ! validate_commit_state; then
        exit 1
    fi

    # Create temp file
    local temp_file=$(mktemp)
    trap "rm -f '$temp_file'" EXIT

    echo "$commit_message" > "$temp_file"

    # Commit
    create_commit "$temp_file"
}
```

**In commit.md skill, update workflow:**
```markdown
## Simplified Workflow

1. Check staged changes: `git status`
2. Draft commit message
3. Show message to user and get approval
4. Run single command:

```bash
git commit -S -m "$(cat <<'EOF'
Your multi-line
commit message
here

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**CRITICAL: Run in FOREGROUND with timeout of 120s**
```

**Benefits:**
- Single bash invocation
- No temp file management needed
- Heredoc keeps message formatting clean
- Forced foreground execution
- Clear timeout prevents infinite hangs

### MEDIUM Priority - Update Skill Documentation

**commit.md improvements:**

1. **Add execution constraints:**
```markdown
## Execution Requirements

**CRITICAL - READ BEFORE RUNNING:**
- MUST run commit command in FOREGROUND (not background)
- MUST set timeout to at least 120000ms (2 minutes)
- MUST check for GPG agent before attempting commit
- If commit fails, provide user with exact command to run manually
```

2. **Simplify workflow to 3 steps:**
```markdown
## Workflow

1. **Verify staged changes**
   ```bash
   git status
   ```

2. **Draft commit message and get user approval**
   - Show the full message
   - Ask: "Ready to commit? (yes/no)"

3. **ONLY after approval, run commit**
   ```bash
   # CRITICAL: Run in FOREGROUND with 120s timeout
   git commit -S -m "$(cat <<'EOF'
   [commit message]
   EOF
   )"
   ```
```

3. **Add troubleshooting section:**
```markdown
## Troubleshooting

**If commit hangs:**
- Check GPG agent: `gpg-connect-agent /bye`
- Test GPG signing: `echo "test" | gpg --sign --local-user [KEY] --armor`
- If GPG prompts, enter passphrase to cache it
- Retry commit

**If commit fails with "Request interrupted":**
- GPG passphrase not cached
- Run manually: `git commit -F /tmp/[saved-message].txt`
```

### LOW Priority - Optimizations

#### 1. Cache Commit Context
Instead of running `git status`, `git diff`, `git log` separately:

```bash
# Single invocation to get all needed info
get_all_context() {
    cat <<EOF
=== STAGED CHANGES ===
$(git diff --cached --stat)

=== RECENT COMMITS ===
$(git log -10 --oneline --no-merges)

=== DIFF ===
$(git diff --cached | head -200)
EOF
}
```

**Saves:** 2-3 bash tool calls → 1 bash tool call

#### 2. Skip Validation if Recently Validated
```bash
# Cache validation result for 60 seconds
VALIDATION_CACHE="/tmp/.commit-validation-${USER}"
if [[ -f "$VALIDATION_CACHE" ]] && [[ $(($(date +%s) - $(stat -f %m "$VALIDATION_CACHE"))) -lt 60 ]]; then
    # Skip validation
else
    validate_commit_state
    touch "$VALIDATION_CACHE"
fi
```

**Saves:** ~500ms per commit attempt

#### 3. Parallel Git Commands
Where safe, run git commands in parallel:

```bash
# Get context (these don't depend on each other)
{
    git log -10 --oneline > /tmp/log.txt &
    git diff --cached --stat > /tmp/stat.txt &
    git diff --cached > /tmp/diff.txt &
    wait
}
```

**Saves:** ~1-2 seconds for large repos

## Implementation Priority

### Phase 1: Critical Fixes (Do First)
1. ✅ **Add background execution detection** (Option A)
   - Prevents hung processes
   - Clear error messages
   - 10 minutes to implement

2. ✅ **Update commit.md with execution constraints**
   - Document MUST run in foreground
   - Add timeout requirement (120s)
   - 5 minutes to implement

3. ✅ **Simplify workflow to use git commit directly**
   - Remove multi-step process
   - Use heredoc pattern
   - 15 minutes to update docs

### Phase 2: Robustness (Do Second)
4. **Add GPG_TTY export and fail-fast mode**
   - Improve GPG reliability
   - Faster failure when passphrase unavailable
   - 20 minutes to implement and test

5. **Add troubleshooting guidance in commit.md**
   - Help users self-resolve GPG issues
   - 10 minutes to document

### Phase 3: Optimization (Do Later)
6. **Cache commit context**
7. **Skip repeated validation**
8. **Parallel git commands**

## Success Metrics

**After implementing Phase 1:**
- ✅ 0% hung processes (down from 75% failure rate)
- ✅ Clear error messages when GPG unavailable
- ✅ Single bash invocation per commit (down from 4-5)
- ✅ Max 120s timeout (down from infinite)

**After implementing Phase 2:**
- ✅ <5s time to failure when GPG unavailable
- ✅ Users can self-resolve GPG issues
- ✅ 95%+ success rate on first attempt

**After implementing Phase 3:**
- ✅ 2-3s faster context gathering
- ✅ <500ms validation overhead

## Proposed Changes

### File Changes Required

1. **docs/plans/commit-workflow-analysis.md** (this file) - Created
2. **claude-code/commands/commit.md** - Major revision
3. **claude-code/commands/commit.sh** - Minor additions
4. **CLAUDE.md** - Add commit troubleshooting reference

### Testing Plan

1. **Test background execution detection:**
   ```bash
   echo | ~/.claude/commands/commit.sh  # Should fail with clear error
   ```

2. **Test foreground commit:**
   ```bash
   # Stage test change
   echo "test" > test.txt && git add test.txt

   # Commit with heredoc
   git commit -S -m "$(cat <<'EOF'
   Test commit
   EOF
   )"

   # Cleanup
   git reset HEAD~1 && rm test.txt
   ```

3. **Test GPG failure modes:**
   ```bash
   # Stop GPG agent
   gpgconf --kill gpg-agent

   # Attempt commit - should fail fast
   # Should see clear error, not hang

   # Restart agent
   gpgconf --launch gpg-agent
   ```

4. **Test in Claude Code:**
   - Use /commit command
   - Verify runs in foreground
   - Verify completes within 120s
   - Verify clear errors on failure

## Related Documentation

- `claude-code/commands/commit.md` - Slash command skill
- `claude-code/commands/commit.sh` - Implementation script (383 lines)
- `CLAUDE.md` - Git commit guidance
- `.claude/settings.json` - Permissions for git commands

## References

- GPG pinentry modes: https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html
- Git commit hooks: https://git-scm.com/docs/githooks
- Claude Code tool execution: claude-code documentation

---

**Next Steps:**
1. Review this analysis
2. Approve implementation approach
3. Implement Phase 1 (critical fixes)
4. Test thoroughly
5. Update improvement plan with learnings
