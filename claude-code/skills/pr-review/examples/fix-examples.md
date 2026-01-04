# PR Fix Examples

Comprehensive examples showing the fix workflow in action.

See [review-examples.md](review-examples.md) for review-only examples.


## Example 5: Fixing PR Review Comments

**User request:** "Fix the review comments on PR #567"

**Skill workflow:**

**Step 1: Fetch feedback**
```bash
gh pr view 567 --json number,title
gh api repos/org/repo/pulls/567/comments
gh pr checkout 567
```

**Step 2: Present plan to user**

```markdown
## PR #567 Review Feedback

I found 4 review comments to address:

### 🔴 Critical (1)
1. **src/auth.js:45** (@security-reviewer)
   - "This allows SQL injection via username parameter"
   - **Fix**: Switch to parameterized query

### 🟡 High Priority (2)
2. **src/api/users.js:123** (@senior-engineer)
   - "Missing error handling when database is down"
   - **Fix**: Add try-catch and return 503 status

3. **tests/auth.test.js:67** (@qa-lead)
   - "Test doesn't cover the edge case where email is null"
   - **Fix**: Add test case for null email

### 🟢 Medium (1)
4. **README.md:234** (@docs-team)
   - "API endpoint example is outdated"
   - **Fix**: Update example to use new response format

Would you like me to:
A) Fix all issues (recommended)
B) Fix only critical/high priority
C) Let me choose specific issues
```

**Step 3: User confirms "A - fix all"**

**Step 4: Make fixes with verification**

```markdown
## Fixing Issues...

### ✅ Fixed #1: SQL Injection (src/auth.js:45)

**Before:**
```javascript
const query = `SELECT * FROM users WHERE username = '${username}'`;
db.query(query);
```

**After:**
```javascript
const query = 'SELECT * FROM users WHERE username = ?';
db.query(query, [username]);
```

**Verification:**
- Linting: ✅ Pass
- Tests: ✅ All auth tests passing
- Security: ✅ Now uses parameterized queries

---

### ✅ Fixed #2: Missing Error Handling (src/api/users.js:123)

**Before:**
```javascript
const users = await db.getUsers();
return res.json(users);
```

**After:**
```javascript
try {
  const users = await db.getUsers();
  return res.json(users);
} catch (error) {
  console.error('Database error:', error);
  return res.status(503).json({
    error: 'Service temporarily unavailable'
  });
}
```

**Verification:**
- Linting: ✅ Pass
- Tests: ✅ Added test for DB down scenario
- Manual test: ✅ Returns 503 when DB unavailable

---

### ✅ Fixed #3: Missing Test Case (tests/auth.test.js:67)

**Added test:**
```javascript
it('should reject login when email is null', async () => {
  const result = await auth.login({ email: null, password: 'test123' });
  expect(result.success).toBe(false);
  expect(result.error).toBe('Invalid email');
});
```

**Verification:**
- Test runs: ✅ New test passing
- Coverage: ✅ Increased from 87% to 89%

---

### ✅ Fixed #4: Outdated Documentation (README.md:234)

**Before:**
```markdown
GET /api/users returns:
{ users: [...] }
```

**After:**
```markdown
GET /api/users returns:
{
  "data": {
    "users": [...],
    "total": 150,
    "page": 1
  }
}
```

**Verification:**
- Markdown linting: ✅ Pass
- Links valid: ✅ All links working

---

## Final Verification

Running full test suite...
```bash
npm test
✅ 247 tests passed
✅ Coverage: 89% (target: 80%)

npm run lint
✅ No linting errors

npm run build
✅ Build successful
```

## Summary

### Fixed (4 issues)

✅ **Critical**: SQL injection vulnerability (src/auth.js:45)
✅ **High**: Missing error handling for DB failures (src/api/users.js:123)
✅ **High**: Added missing test case for null email (tests/auth.test.js)
✅ **Medium**: Updated outdated API documentation (README.md:234)

### Test Results
- All 247 tests passing ✅
- Code coverage: 89% (▲ 2%)
- Linting: Clean ✅
- Build: Successful ✅

### Changes Ready
```bash
git status
# 4 files modified:
#   src/auth.js
#   src/api/users.js
#   tests/auth.test.js
#   README.md
```

### Next Steps

1. **Review changes**: `git diff`
2. **Commit changes**: `git commit -m "Address review feedback from @reviewers"`
3. **Push to PR**: `git push`
4. **Notify reviewers**:
   ```bash
   gh pr comment 567 --body "All review feedback addressed. Ready for re-review."
   ```

Would you like me to push these changes?
```

---

## Example 6: Fixing Failing CI Checks

**User request:** "Fix the failing tests on my PR"

**Output:**

```markdown
## PR #892: Fixing Failing CI Checks

### Current Status

**Failing Checks:**
- ❌ Unit Tests: 3 failures
- ❌ E2E Tests: 1 failure
- ✅ Linting: Passing
- ✅ Build: Passing

### Analyzing Failures...

Fetched test output from CI:
```bash
gh pr checks 892 --json name,state,link
```

**Failed Tests:**
1. `test/user.test.js` - "User creation fails when email exists"
2. `test/user.test.js` - "User update fails with invalid data"
3. `test/auth.test.js` - "Token refresh returns 401"
4. `test/e2e/checkout.test.js` - "Complete checkout flow times out"

### Fixing Tests...

#### ✅ Fixed: "User creation fails when email exists"

**Issue**: Test expects error code 409, but code returns 400

**Root cause**:
```javascript
// src/api/users.js:78
return res.status(400).json({ error: 'Email exists' });
```

**Fix**:
```javascript
// Should be 409 Conflict, not 400 Bad Request
return res.status(409).json({ error: 'Email exists' });
```

**Verification**: Test now passing ✅

---

#### ✅ Fixed: "User update fails with invalid data"

**Issue**: Mock data format changed but test not updated

**Fix**: Updated test mock to match new API format
```javascript
// Before
{ user: { id: 1, name: 'Test' } }

// After
{ data: { user: { id: 1, name: 'Test' } } }
```

**Verification**: Test now passing ✅

---

#### ✅ Fixed: "Token refresh returns 401"

**Issue**: Test token expired, needs to be regenerated

**Fix**: Use `generateTestToken()` helper instead of hardcoded token

**Verification**: Test now passing ✅

---

#### ✅ Fixed: "Complete checkout flow times out"

**Issue**: E2E test timeout increased from 5s to 30s (payment processing is slow)

**Root cause**: Added 3rd party payment verification, needs more time

**Fix**: Increased test timeout to 45 seconds
```javascript
it('should complete checkout', async () => {
  // ... test code
}, 45000); // Increased from 5000
```

**Alternative considered**: Mock the payment service (decided against to test real integration)

**Verification**: E2E test now passing ✅

---

## Final Test Run

```bash
npm test
✅ All 247 tests passing

npm run test:e2e
✅ All 18 E2E tests passing

npm run lint
✅ No linting errors
```

## Summary

### Fixed (4 test failures)

✅ User creation test: Changed status code from 400 to 409
✅ User update test: Updated mock data format
✅ Token refresh test: Use generated token instead of hardcoded
✅ E2E checkout test: Increased timeout to account for payment processing

### All Checks Passing
- ✅ Unit Tests (247 passing)
- ✅ E2E Tests (18 passing)
- ✅ Linting
- ✅ Build

### Ready to Merge
PR #892 now has all checks passing and is ready for review/merge.

```bash
git push  # Push fixes to PR branch
```
```

---

## Example 7: Resolving Merge Conflicts

**User request:** "Help me resolve the merge conflicts on PR #234"

**Output:**

```markdown
## PR #234: Resolving Merge Conflicts

### Conflict Status

**Files in conflict:** 3
- `src/config/database.js`
- `src/models/user.js`
- `package.json`

### Resolving Conflicts...

Checking out PR and rebasing on latest main:
```bash
gh pr checkout 234
git fetch origin main
git rebase origin/main
```

**Conflict 1: src/config/database.js**

```javascript
<<<<<<< HEAD (your changes)
const pool = new Pool({
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  max: 20  // Your change: increased pool size
});
=======
const pool = new Pool({
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,  // Main added: port config
  max: 10
});
>>>>>>> origin/main
```

**Resolution**: Keep both changes
```javascript
const pool = new Pool({
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,  // From main
  max: 20  // From your PR
});
```

**Verification**: Database connection test passes ✅

---

**Conflict 2: src/models/user.js**

```javascript
<<<<<<< HEAD
async findByEmail(email) {
  return db.query('SELECT * FROM users WHERE email = ?', [email]);
}
=======
async findByEmail(email) {
  // Main branch added caching
  const cached = await cache.get(`user:${email}`);
  if (cached) return cached;

  const user = await db.query('SELECT * FROM users WHERE email = ?', [email]);
  await cache.set(`user:${email}`, user);
  return user;
}
>>>>>>> origin/main
```

**Resolution**: Keep main's caching logic (it's a necessary optimization)
```javascript
async findByEmail(email) {
  const cached = await cache.get(`user:${email}`);
  if (cached) return cached;

  const user = await db.query('SELECT * FROM users WHERE email = ?', [email]);
  await cache.set(`user:${email}`, user);
  return user;
}
```

**Verification**: User lookup tests pass ✅

---

**Conflict 3: package.json**

```json
<<<<<<< HEAD
"dependencies": {
  "express": "^4.18.2",
  "pg": "^8.11.0"
}
=======
"dependencies": {
  "express": "^4.19.0",
  "pg": "^8.11.0",
  "redis": "^4.6.0"
}
>>>>>>> origin/main
```

**Resolution**: Keep main's versions + redis (needed for caching)
```json
"dependencies": {
  "express": "^4.19.0",
  "pg": "^8.11.0",
  "redis": "^4.6.0"
}
```

**Verification**:
```bash
npm install
✅ Dependencies installed successfully
npm test
✅ All tests passing
```

---

## Completing Rebase

```bash
git add .
git rebase --continue
git push --force-with-lease
```

## Summary

### Resolved (3 conflicts)

✅ **database.js**: Merged pool size increase with port configuration
✅ **user.js**: Kept main's caching implementation
✅ **package.json**: Merged dependencies, upgraded express version

### Verification
- ✅ All tests passing
- ✅ Build successful
- ✅ No remaining conflicts

### PR Status
PR #234 is now conflict-free and up-to-date with main. Ready for review.
```

---

## Example 8: Addressing All Three Types of Comments

**User request:** "Address all the feedback on PR #999"

**Skill workflow showing comprehensive comment fetching:**

**Step 1: Fetch ALL comment types**

```bash
# Fetch issue comments (general PR discussion)
gh api repos/org/repo/issues/999/comments

# Fetch review comments (inline code comments)
gh api repos/org/repo/pulls/999/comments

# Fetch review summaries (overall review decisions)
gh api repos/org/repo/pulls/999/reviews

# Get review threads with resolution status
gh pr view 999 --json reviewThreads
```

**Step 2: Organize comments by type**

```markdown
## PR #999 Feedback Analysis

Found feedback across 3 comment types:

### 🔴 Critical Issues (2)

**Review Comment (inline code):**
1. **src/api/payments.js:156** (@security-team)
   - **Thread**: Unresolved
   - **Comment**: "This endpoint doesn't validate the payment amount. Attacker could set amount to $0.01"
   - **Type**: Security vulnerability
   - **Fix**: Add server-side amount validation

**Review Summary:**
2. **@tech-lead** requested changes
   - **Summary**: "This PR introduces a race condition in the payment processing. The order must be locked before charging."
   - **Type**: Concurrency bug
   - **Fix**: Implement order locking mechanism

### 🟡 High Priority (3)

**Review Comment (inline code):**
3. **src/models/order.js:89** (@senior-dev)
   - **Thread**: Unresolved
   - **Comment**: "What happens if the database transaction fails halfway through?"
   - **Type**: Error handling
   - **Fix**: Add transaction rollback logic

**Issue Comment (general):**
4. **PR Comment** by @qa-lead (2 hours ago)
   - **Comment**: "I tested this locally and orders are getting duplicated if the user clicks 'Pay' twice quickly. We need debouncing or idempotency."
   - **Type**: Functional bug
   - **Fix**: Add idempotency key to payment processing

**Review Comment (inline code):**
5. **tests/payments.test.js:234** (@test-automation)
   - **Thread**: Unresolved
   - **Comment**: "Missing test case: what if payment gateway returns 500?"
   - **Type**: Test coverage
   - **Fix**: Add test for gateway errors

### 🟢 Medium (2)

**Issue Comment (general):**
6. **PR Comment** by @product-manager (4 hours ago)
   - **Comment**: "Can we add a confirmation email after successful payment? Users have been asking for this."
   - **Type**: Feature request
   - **Fix**: Add email notification

**Review Comment (inline code):**
7. **README.md:145** (@docs-team)
   - **Thread**: Unresolved
   - **Comment**: "The payment API documentation is missing the new 'metadata' field"
   - **Type**: Documentation
   - **Fix**: Update API docs

### Summary
- **Total**: 7 pieces of feedback
- **Review comments** (inline): 5
- **Issue comments** (general): 2
- **Review summaries**: 1
- **Unresolved threads**: 6
- **Bots filtered**: 3 (CI status comments)

Would you like me to:
A) Fix all issues (recommended)
B) Fix only critical/high priority
C) Let me choose specific issues
D) Review and discuss approach first
```

**Step 3: User chooses "A - Fix all"**

**Step 4: Implement fixes systematically**

```markdown
## Fixing All Feedback...

### ✅ Fixed #1: Payment Amount Validation (CRITICAL)

**Location**: src/api/payments.js:156
**Reviewer**: @security-team
**Type**: Review comment (inline code)

**Before:**
```javascript
router.post('/charge', async (req, res) => {
  const { orderId, paymentMethod } = req.body;
  const charge = await stripe.charges.create({
    amount: req.body.amount, // ⚠️ No validation!
    currency: 'usd',
    source: paymentMethod
  });
  // ...
});
```

**After:**
```javascript
router.post('/charge', async (req, res) => {
  const { orderId, paymentMethod } = req.body;

  // Validate amount from order record, not user input
  const order = await Order.findById(orderId);
  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  }

  if (order.total <= 0) {
    return res.status(400).json({ error: 'Invalid order amount' });
  }

  const charge = await stripe.charges.create({
    amount: order.total, // ✅ Use server-calculated amount
    currency: 'usd',
    source: paymentMethod,
    metadata: { orderId: order.id }
  });
  // ...
});
```

**Verification**:
- Security scan: ✅ No vulnerabilities
- Tests: ✅ Added test for amount tampering
- Manual test: ✅ Rejects manipulated amounts

---

### ✅ Fixed #2: Race Condition in Payment Processing (CRITICAL)

**Location**: Multiple files
**Reviewer**: @tech-lead (Review summary)
**Type**: Review summary (overall feedback)

**Fix**: Implemented order locking with database transaction:

```javascript
// src/services/payment-processor.js
async processPayment(orderId, paymentMethod) {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Lock order for update
    const order = await Order.findOneAndUpdate(
      { _id: orderId, status: 'pending' },
      { status: 'processing' },
      { session, new: true }
    );

    if (!order) {
      throw new Error('Order not available for processing');
    }

    // Process payment
    const charge = await this.chargePayment(order, paymentMethod);

    // Update order
    order.status = 'paid';
    order.paymentId = charge.id;
    await order.save({ session });

    await session.commitTransaction();
    return order;

  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
}
```

**Verification**:
- Concurrency test: ✅ No duplicate charges
- Load test: ✅ Handles concurrent requests
- Manual test: ✅ Double-click doesn't create duplicates

---

### ✅ Fixed #3: Transaction Rollback Logic (HIGH)

**Location**: src/models/order.js:89
**Reviewer**: @senior-dev
**Type**: Review comment (inline code)

**Fix**: Already handled by transaction in #2, added explicit error handling:

```javascript
// Now uses transactions with automatic rollback
// Added comprehensive error messages
catch (error) {
  await session.abortTransaction();
  logger.error('Payment transaction failed', { orderId, error });

  // Send alert for failed payments
  await alertService.notifyFailedPayment(orderId, error);

  throw new PaymentError('Payment processing failed', {
    orderId,
    reason: error.message
  });
}
```

**Verification**: ✅ Simulated DB failures, rollback works correctly

---

### ✅ Fixed #4: Duplicate Orders from Double-Click (HIGH)

**Location**: Frontend + Backend
**Reviewer**: @qa-lead
**Type**: Issue comment (general PR feedback)

**Frontend fix** (debouncing):
```javascript
// src/components/CheckoutButton.jsx
const handlePayment = useMemo(
  () => debounce(async () => {
    setIsProcessing(true);
    try {
      await processPayment(orderId);
    } finally {
      setIsProcessing(false);
    }
  }, 1000, { leading: true, trailing: false }),
  [orderId]
);
```

**Backend fix** (idempotency):
```javascript
// Use idempotency key
router.post('/charge', async (req, res) => {
  const idempotencyKey = req.headers['idempotency-key'];
  if (!idempotencyKey) {
    return res.status(400).json({ error: 'Idempotency-Key header required' });
  }

  // Check if already processed
  const existing = await PaymentIntent.findOne({ idempotencyKey });
  if (existing) {
    return res.json({ order: existing.order, alreadyProcessed: true });
  }

  // Process payment with idempotency key
  // ...
});
```

**Verification**:
- Manual test: ✅ Double-click doesn't duplicate
- E2E test: ✅ Added test case
- QA approval: ✅ @qa-lead verified fix

---

### ✅ Fixed #5: Missing Test for Gateway Errors (HIGH)

**Location**: tests/payments.test.js:234
**Reviewer**: @test-automation
**Type**: Review comment (inline code)

**Added test:**
```javascript
describe('Payment Gateway Errors', () => {
  it('should handle 500 errors from payment gateway', async () => {
    // Mock gateway to return 500
    stripe.charges.create.mockRejectedValue({
      statusCode: 500,
      message: 'Internal Server Error'
    });

    const response = await request(app)
      .post('/api/payments/charge')
      .send({ orderId: testOrder.id, paymentMethod: 'tok_visa' })
      .expect(503);

    expect(response.body.error).toBe('Payment service temporarily unavailable');

    // Verify order not marked as paid
    const order = await Order.findById(testOrder.id);
    expect(order.status).toBe('pending');
  });
});
```

**Verification**: ✅ Test passing, coverage increased to 91%

---

### ✅ Fixed #6: Add Confirmation Email (MEDIUM)

**Location**: New feature
**Reviewer**: @product-manager
**Type**: Issue comment (general feature request)

**Implementation:**
```javascript
// src/services/email-service.js
async sendPaymentConfirmation(order) {
  await this.sendEmail({
    to: order.customer.email,
    subject: `Payment Confirmation - Order #${order.number}`,
    template: 'payment-confirmation',
    data: {
      orderNumber: order.number,
      amount: formatCurrency(order.total),
      items: order.items,
      paymentMethod: order.paymentMethod
    }
  });
}

// src/services/payment-processor.js (after successful payment)
await emailService.sendPaymentConfirmation(order);
```

**Verification**:
- Test: ✅ Email sent after payment
- Manual test: ✅ Received confirmation email
- PM approval: ✅ @product-manager reviewed template

---

### ✅ Fixed #7: Update API Documentation (MEDIUM)

**Location**: README.md:145
**Reviewer**: @docs-team
**Type**: Review comment (inline code)

**Updated documentation:**
```markdown
## POST /api/payments/charge

**Request:**
```json
{
  "orderId": "string (required)",
  "paymentMethod": "string (required)",
  "metadata": {                    // ✨ NEW
    "customerId": "string",
    "campaign": "string",
    "referrer": "string"
  }
}
```

**Response:**
```json
{
  "order": { ... },
  "paymentId": "string",
  "receiptUrl": "string"           // ✨ NEW
}
```
```

**Verification**: ✅ Docs team approved

---

## Final Verification

```bash
npm test
✅ All 312 tests passing (+5 new tests)
✅ Coverage: 91% (▲ 3%)

npm run lint
✅ No linting errors

npm run build
✅ Build successful

npm run test:e2e
✅ All E2E tests passing
```

## Summary

### Fixed (7 issues across ALL comment types)

**Review Comments (inline code):**
✅ #1: Payment amount validation (src/api/payments.js:156)
✅ #3: Transaction rollback (src/models/order.js:89)
✅ #5: Gateway error test (tests/payments.test.js:234)
✅ #7: API documentation (README.md:145)

**Issue Comments (general feedback):**
✅ #4: Duplicate order prevention (frontend + backend)
✅ #6: Confirmation email feature (new)

**Review Summaries (overall review):**
✅ #2: Race condition fix (payment processor)

### Changes Made
- **Files modified**: 8
- **Lines added**: 247
- **Lines removed**: 63
- **Tests added**: 5
- **Security issues fixed**: 2
- **New features**: 1 (email confirmation)

### All Feedback Addressed
- ✅ 5 inline code review comments resolved
- ✅ 2 general PR comments addressed
- ✅ 1 review summary (changes requested) resolved
- ✅ All unresolved threads now resolved

### Next Steps

1. **Push changes**: `git push`
2. **Notify all reviewers**:
   ```bash
   gh pr comment 999 --body "All feedback addressed across all comment types:

   @security-team - Payment validation added
   @tech-lead - Race condition fixed with locking
   @senior-dev - Transaction rollback implemented
   @qa-lead - Idempotency added, duplicate orders prevented
   @test-automation - Gateway error test added
   @product-manager - Confirmation email implemented
   @docs-team - API docs updated

   All tests passing. Ready for re-review."
   ```
3. **Request re-review from all reviewers**
4. **Mark all threads as resolved** (or wait for reviewers to verify)
```

---

**Last Updated:** 2026-01-04
