# Agent Harness Best Practices: A Comprehensive Guide

**Date**: 2025-12-31
**Focus**: Best practices for working with Claude Code and building effective agent harnesses

---

## Table of Contents

1. [What is an Agent Harness?](#what-is-an-agent-harness)
2. [Core Principles of Effective Agent Harnesses](#core-principles)
3. [Claude Code Architecture](#claude-code-architecture)
4. [Best Practices for Agent Instructions](#best-practices-for-instructions)
5. [Context Management Strategies](#context-management)
6. [Workflow Patterns](#workflow-patterns)
7. [Security and Safety](#security-and-safety)
8. [Production Deployment](#production-deployment)
9. [Practical Implementation Guide](#practical-implementation)
10. [Common Pitfalls and Solutions](#common-pitfalls)

---

## What is an Agent Harness?

An **agent harness** is the infrastructure and configuration layer that enables AI coding agents to work effectively and safely in your development environment. Think of it as the "operating system" for your AI agent—it provides:

- **Context and Instructions**: What the agent needs to know about your codebase
- **Tool Access and Permissions**: What the agent is allowed to do
- **Workflow Patterns**: How the agent should approach tasks
- **Safety Boundaries**: What the agent must never do
- **Memory and Continuity**: How the agent maintains context across sessions

### The Agent Stack

According to current research, the AI agent ecosystem consists of three layers:

1. **Agent Frameworks** - High-level abstractions (LangChain, CrewAI, AutoGPT)
2. **Agent Runtimes** - Execution environments with tool access (Claude Code, Cursor, Windsurf)
3. **Agent Harnesses** - Configuration and orchestration (your CLAUDE.md, hooks, subagents)

This document focuses on **agent harnesses**—the configuration layer that makes agents effective in your specific context.

---

## Core Principles of Effective Agent Harnesses

Based on research from Anthropic, UiPath, and the broader AI agent community, effective agent harnesses follow these core principles:

### 1. Context Efficiency

**Problem**: Tools and instructions consume valuable context window space.

**Solution**: Be surgical about what you include.

```markdown
❌ BAD: Verbose, redundant instructions
# When you need to write code, you should think carefully about the code
# you're writing and make sure it's good code that follows best practices
# and is well-structured and maintainable...

✅ GOOD: Concise, actionable rules
- MUST use TypeScript strict mode
- MUST write tests for business logic
- MUST validate user inputs
```

### 2. Sensible Defaults

**Problem**: Too much configuration creates cognitive load.

**Solution**: Harnesses should "just work" with minimal setup.

```yaml
# Good harness design: pre-configured defaults
---
name: code-reviewer
model: sonnet  # Default model pre-selected
tools: [Read, Grep, Glob]  # Only needed tools
permissionMode: default  # Safe by default
---
```

### 3. Progressive Disclosure

**Problem**: Agents get overwhelmed with too much information upfront.

**Solution**: Reference detailed docs when needed, keep core instructions minimal.

```markdown
## Quick Start
- Use `npm test` to run tests
- Use `npm run lint` to check code quality

## Detailed Standards
See @docs/testing-guide.md for comprehensive testing patterns.
See @docs/api-design.md for REST API conventions.
```

### 4. Multi-Session Continuity

**Problem**: Agents start fresh each session with no memory.

**Solution**: Design for discrete sessions with clear artifacts.

```markdown
## Session Management Pattern

### End-of-Session Checklist
- MUST document progress in TODO.md
- MUST commit changes with descriptive messages
- MUST update PROGRESS.md with next steps
- SHOULD note any blockers or decisions needed

### Start-of-Session Checklist
- Read TODO.md for current tasks
- Read PROGRESS.md for context
- Check recent git commits for changes
```

---

## Claude Code Architecture

### Design Philosophy

Claude Code prioritizes **architectural simplicity**:

- **One main loop** - No complex state machines
- **Simple search** - Basic but effective
- **Flat message history** - No complicated threading
- **Single-level delegation** - Subagents can't spawn more subagents

This intentional simplicity makes Claude Code:
- **Predictable** - Behavior is transparent
- **Debuggable** - Easy to understand what happened
- **Customizable** - Simple to extend and modify
- **Safe** - Fewer moving parts means fewer failure modes

### Subagent System

Claude Code uses **subagents** for specialized tasks. Each subagent:

```markdown
---
name: security-auditor
description: Security-focused code review. Use when reviewing auth, payment, or data handling code.
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: acceptEdits
---

# Security Auditor Subagent

## Your Role
You are a security expert reviewing code for vulnerabilities.

## When to Use
- Reviewing authentication/authorization code
- Auditing payment processing logic
- Checking data handling for PII/sensitive info
- Pre-deployment security review

## Review Process
1. Read target files using Read tool
2. Search for patterns using Grep (SQL, passwords, tokens)
3. Check for OWASP Top 10 vulnerabilities
4. Document findings with severity ratings
5. Suggest specific fixes with code examples

## Critical Checks
- MUST check for hardcoded credentials
- MUST verify input validation on all user data
- MUST check for SQL injection vulnerabilities
- MUST verify proper error handling (no data leakage)
- MUST check authentication/authorization on endpoints

## Output Format
Present findings as:
- **Critical**: Security vulnerabilities requiring immediate fix
- **High**: Significant security concerns
- **Medium**: Security improvements recommended
- **Low**: Best practice suggestions
```

**Key characteristics**:
- Separate context window (doesn't pollute main conversation)
- Restricted tool access (only gets what it needs)
- Custom system prompt (specialized expertise)
- Independent execution (completes task and returns)

### Memory Hierarchy

Claude Code loads instructions in this priority order (highest first):

1. **Enterprise policy** - `~/.claude/enterprise/CLAUDE.md` (IT-managed)
2. **Project instructions** - `./CLAUDE.md` or `./.claude/CLAUDE.md` (team-shared)
3. **Modular rules** - `./.claude/rules/*.md` (topic-specific)
4. **User preferences** - `~/.claude/CLAUDE.md` (personal)
5. **Local overrides** - `./CLAUDE.local.md` (project-specific, gitignored)

**Best practice**: Use project-level for team standards, user-level for personal preferences.

### Skills vs Subagents

**Skills** modify the main agent's behavior:
```markdown
---
name: api-designer
description: REST API design patterns
---
# This skill teaches the MAIN agent API design
# It affects the current conversation context
```

**Subagents** delegate to specialized agents:
```markdown
---
name: api-reviewer
description: Reviews API designs for consistency
tools: Read, Grep
---
# This creates a SEPARATE agent
# It runs independently and returns results
```

**When to use each**:
- **Skill**: Teach the main agent a new capability (formatting, conventions)
- **Subagent**: Delegate a discrete task (review, testing, debugging)

---

## Best Practices for Agent Instructions

### The Agent Rules Specification

The [Agent Rules specification](https://agents.md/) defines a standard format for agent instructions:

**Core principle**: Use RFC 2119 keywords (MUST, SHOULD, MAY) in imperative statements.

#### RFC 2119 Keywords

| Keyword | Meaning | Use When |
|---------|---------|----------|
| **MUST** | Absolute requirement | Critical, non-negotiable rules |
| **MUST NOT** | Absolute prohibition | Unsafe or incorrect patterns |
| **SHOULD** | Recommended | Best practices, preferred patterns |
| **SHOULD NOT** | Not recommended | Discouraged but not forbidden |
| **MAY** | Optional | Nice-to-have, agent discretion |

#### Example: Good Agent Rules Format

```markdown
# TypeScript Development Rules

## Type Safety
- MUST use explicit return types on all exported functions
- MUST enable strict mode in tsconfig.json
- MUST NOT use `any` type (use `unknown` and narrow)
- SHOULD use branded types for domain concepts
- MAY use type assertions only when type narrowing impossible

## Null Safety
- MUST use strict null checks
- MUST use nullish coalescing (??) not logical OR (||)
- SHOULD use optional chaining (?.) for safe property access
- MUST NOT assume values are non-null without checking

## Async Operations
- MUST use async/await instead of .then() chains
- MUST handle promise rejections explicitly
- MUST NOT create fire-and-forget promises
- SHOULD use Promise.all() for concurrent operations
```

### Flat, Scannable Format

Agents parse instructions quickly when they're structured as flat bullet lists:

```markdown
❌ BAD: Nested complexity
## Authentication
When working with authentication, you need to be careful about several things:
- First, consider security aspects
  - This includes password handling
    - Which should use bcrypt
      - With minimum 10 rounds
  - And also token management
    - JWT tokens should be short-lived
      - Typically 15 minutes
- Second, think about user experience...

✅ GOOD: Flat, scannable
## Authentication Rules
- MUST hash passwords with bcrypt (minimum 10 rounds)
- MUST use JWT tokens with 15-minute expiration
- MUST store refresh tokens securely (httpOnly cookies)
- MUST implement rate limiting on login endpoints (5 attempts/15min)
- SHOULD use 2FA for sensitive operations
- SHOULD log authentication events for audit
```

### Specificity Over Vagueness

```markdown
❌ BAD: Vague guidance
- Write good code
- Follow best practices
- Be careful with security
- Add appropriate tests

✅ GOOD: Specific, actionable
- MUST achieve minimum 80% test coverage on service layer
- MUST validate all user inputs with class-validator decorators
- MUST use parameterized queries (never string concatenation for SQL)
- MUST include JSDoc with @param, @returns, @throws on exported functions
```

### Effective Subagent Descriptions

The `description` field determines when Claude delegates to a subagent. Make it trigger-rich:

```yaml
❌ BAD: Too vague
description: Helps with code

✅ GOOD: Specific with natural triggers
description: Expert code reviewer focusing on security vulnerabilities, performance issues, and test coverage. Use when reviewing code, checking quality, auditing security, or before merging PRs.
```

**Trigger words to include**:
- **Review agents**: review, check, audit, inspect, analyze quality
- **Debug agents**: debug, troubleshoot, fix, investigate, broken, failing
- **Test agents**: test, verify, validate, check coverage, run tests
- **Security agents**: security, vulnerabilities, audit, penetration test

---

## Context Management Strategies

### The Context Challenge

Modern LLMs have large context windows (100k+ tokens for Claude), but **tool definitions consume significant space**. A well-designed harness minimizes context waste.

### Strategy 1: Tool Minimalism

Only grant tools the agent actually needs:

```typescript
// ❌ BAD: Kitchen sink approach
{
  allowedTools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep",
                 "WebSearch", "WebFetch", "Task", "TodoWrite", ...]
}

// ✅ GOOD: Minimal, task-specific
{
  allowedTools: ["Read", "Grep"]  // Read-only exploration
}
```

### Strategy 2: Compact System Prompts

Use references instead of inlining large documents:

```markdown
❌ BAD: Inline entire API spec (2000+ lines)
## API Endpoints

### GET /api/users
Returns a list of users...
[entire OpenAPI spec pasted]

✅ GOOD: Reference with summary
## API Endpoints
See @docs/api-spec.yaml for complete API documentation.

Quick reference:
- User management: `/api/users` (GET, POST, PATCH, DELETE)
- Authentication: `/api/auth/login`, `/api/auth/refresh`
- Projects: `/api/projects` (CRUD operations)
```

### Strategy 3: Automatic Summarization

The Claude Agent SDK includes automatic context management:

```typescript
import { query, ClaudeAgentOptions } from '@anthropic-ai/agent-sdk';

for await (const message of query({
  prompt: "Analyze this large codebase",
  options: {
    compact: true,  // Auto-summarize when approaching context limit
    allowedTools: ["Read", "Grep", "Glob"]
  }
})) {
  // Agent automatically condenses previous messages when needed
}
```

### Strategy 4: Session Artifacts

Design for discrete sessions with persistent artifacts:

```markdown
## Multi-Session Pattern

### Session Artifacts (persist between sessions)
- `TODO.md` - Current tasks and priorities
- `PROGRESS.md` - What's been completed, blockers, decisions
- `ARCHITECTURE.md` - High-level design decisions
- Git commits - Incremental progress with descriptive messages

### Session Start Routine
1. Read TODO.md for current context
2. Read PROGRESS.md for recent work
3. Check git log for latest changes
4. Begin work on next prioritized task

### Session End Routine
1. Update TODO.md with remaining work
2. Update PROGRESS.md with accomplishments and blockers
3. Commit changes with descriptive messages
4. Note any questions or decisions needed for next session
```

**Anthropic's recommendation**: Use an "initializer agent" for the first session that sets up the environment, then "coding agents" that make incremental progress using the artifacts left by previous sessions.

---

## Workflow Patterns

### Pattern 1: Plan-Act-Reflect

The most effective pattern for complex tasks:

```
1. PLAN (read-only exploration)
   - Read relevant files
   - Search for patterns
   - Understand existing architecture
   - Draft solution approach

2. ACT (make changes)
   - Implement planned changes
   - Follow established patterns
   - Make atomic commits

3. REFLECT (verify work)
   - Run tests and verify they pass
   - Check for regressions
   - Review code quality
   - Document what was done
```

**Implementation**:
```markdown
# Workflow Instructions

## For Complex Tasks
MUST follow Plan-Act-Reflect workflow:

### Planning Phase
- MUST use Explore subagent or manual search (read-only)
- MUST understand existing patterns before proposing changes
- MUST identify all files that need modification
- MUST draft approach and get user approval if non-trivial

### Action Phase
- MUST make changes incrementally (one logical change at a time)
- MUST run tests after each change
- MUST commit working increments
- SHOULD add tests for new functionality

### Reflection Phase
- MUST verify all tests pass
- MUST check for unintended side effects
- MUST review code quality (no TODOs, proper error handling)
- MUST document significant changes in comments or PROGRESS.md
```

### Pattern 2: Specialized Subagent Chains

For multi-step workflows, chain specialized subagents:

```markdown
## PR Review Workflow

When reviewing a pull request:

1. Use `explorer` subagent to identify changed files
2. Use `test-runner` subagent to verify tests pass
3. Use `security-auditor` subagent to check for vulnerabilities
4. Use `code-reviewer` subagent to assess quality
5. Synthesize findings into coherent review

Each subagent runs independently with focused tools and expertise.
```

### Pattern 3: Human-in-the-Loop

For high-stakes operations, require human approval:

```markdown
## Deployment Workflow

### Pre-Deployment (automated)
- Run full test suite
- Check code coverage thresholds
- Verify no security vulnerabilities
- Build production artifacts
- Generate deployment checklist

### Deployment (human-approved)
- MUST present deployment checklist to user
- MUST wait for explicit approval
- MUST NOT proceed without confirmation
- SHOULD provide rollback instructions

### Post-Deployment (automated)
- Monitor error rates
- Check key metrics
- Alert on anomalies
```

**Implementation with hooks**:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(command:deploy.*)",
        "hooks": [
          {
            "type": "requireApproval",
            "message": "About to deploy to production. Proceed?"
          }
        ]
      }
    ]
  }
}
```

### Pattern 4: Incremental Validation

Validate continuously, not just at the end:

```markdown
## Development Workflow

### After Each Code Change
- MUST run affected tests immediately
- MUST fix failures before proceeding
- SHOULD run linter on changed files
- SHOULD check type errors incrementally

### Before Completing Task
- MUST run full test suite
- MUST verify no new linter errors
- MUST verify no new type errors
- MUST verify changes work in development environment

### Before Creating PR
- MUST ensure all tests pass
- MUST ensure no linter errors
- MUST ensure no type errors
- MUST write descriptive PR description
```

---

## Security and Safety

### Input Validation

Always validate untrusted input in agent prompts:

```bash
# ❌ DANGEROUS: Command injection vulnerability
PROMPT="Delete files matching $USER_INPUT"
claude "$PROMPT"

# ✅ SAFE: Validate input first
if [[ "$USER_INPUT" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
    PROMPT="Delete files matching $USER_INPUT"
    claude "$PROMPT"
else
    echo "Invalid input"
    exit 1
fi
```

### Tool Permission Boundaries

Use `permissionMode` to control agent capabilities:

```json
{
  "permissionMode": "acceptEdits",  // Allow file edits without approval
  "permissions": {
    "allow": [
      "tool:Read",
      "tool:Grep",
      "tool:Glob",
      "bash:git status",
      "bash:npm test"
    ],
    "deny": [
      "bash:rm *",
      "bash:sudo *",
      "bash:git push",
      "bash:npm publish"
    ]
  }
}
```

**Permission modes**:
- `default` - Ask for approval on destructive operations
- `acceptEdits` - Auto-approve file edits, ask for bash commands
- `acceptAll` - Auto-approve everything (⚠️ use carefully)
- `plan` - Read-only mode, no modifications allowed

### Credential Management

Never hardcode credentials in agent configurations:

```markdown
❌ DANGEROUS: Hardcoded secrets
## Database Connection
- Host: db.example.com
- Password: MySecretPassword123
- API Key: sk_live_abc123xyz

✅ SAFE: Reference environment variables
## Database Connection
- Use environment variables from .env.local
- Required: DATABASE_URL, API_KEY
- MUST verify .env.local is in .gitignore
- SHOULD use secret management service in production
```

### Audit Logging

Track what agents do, especially in production:

```typescript
// Audit all file modifications
async function auditFileChange(input, toolUseId, context) {
    const filePath = input.tool_input?.file_path;
    const timestamp = new Date().toISOString();

    await appendFile('./audit.log',
        `${timestamp} | ${toolUseId} | MODIFIED: ${filePath}\n`
    );

    return {};  // Continue with tool execution
}

// Configure in harness
{
  hooks: {
    PostToolUse: [
      {
        matcher: "Write|Edit",
        hooks: [auditFileChange]
      }
    ]
  }
}
```

### Rate Limiting and Quotas

Prevent runaway agents from excessive API usage:

```typescript
let requestCount = 0;
const MAX_REQUESTS = 100;

async function checkRateLimit(input, toolUseId, context) {
    requestCount++;
    if (requestCount > MAX_REQUESTS) {
        throw new Error(`Rate limit exceeded: ${MAX_REQUESTS} requests`);
    }
    return {};
}

{
  hooks: {
    PreToolUse: [
      {
        matcher: "*",  // All tools
        hooks: [checkRateLimit]
      }
    ]
  }
}
```

---

## Production Deployment

### Evaluation and Testing

From UiPath's 2025 best practices, production agents MUST have:

1. **Evaluation Datasets**: Test cases covering common scenarios
2. **Trace Logs**: Full execution logs for debugging
3. **Regression Metrics**: Track accuracy over time
4. **Safety Checks**: Validate outputs before execution

```python
# Example: Agent evaluation framework
import anthropic
from typing import List, Dict

class AgentEvaluator:
    def __init__(self, test_cases: List[Dict]):
        self.test_cases = test_cases
        self.results = []

    async def evaluate(self, agent_query_fn):
        for case in self.test_cases:
            result = await agent_query_fn(
                prompt=case['input'],
                expected_output=case['expected']
            )

            self.results.append({
                'test': case['name'],
                'passed': self._check_output(result, case['expected']),
                'actual': result,
                'expected': case['expected']
            })

    def _check_output(self, actual, expected):
        # Implement your validation logic
        return actual == expected

    def report(self):
        passed = sum(1 for r in self.results if r['passed'])
        total = len(self.results)
        print(f"Passed: {passed}/{total} ({passed/total*100:.1f}%)")

        for result in self.results:
            status = "✓" if result['passed'] else "✗"
            print(f"{status} {result['test']}")

# Usage
evaluator = AgentEvaluator([
    {
        'name': 'Add TODO comment',
        'input': 'Add a TODO to refactor this function',
        'expected': '// TODO: Refactor this function'
    },
    # ... more test cases
])

await evaluator.evaluate(my_agent_query)
evaluator.report()
```

### Versioning and Rollback

Version everything:

```
.claude/
├── agents/
│   └── code-reviewer/
│       ├── v1.0.0.md
│       ├── v1.1.0.md
│       └── current.md → v1.1.0.md  # Symlink
├── CLAUDE.md
└── rules/
    └── typescript/
        ├── v1.0.0.md
        └── current.md → v1.0.0.md
```

**Rollback process**:
```bash
# Rollback to previous version
cd .claude/agents/code-reviewer
ln -sf v1.0.0.md current.md

# Verify rollback
claude --dry-run "Review this code"
```

### Monitoring and Alerting

Monitor agent behavior in production:

```typescript
// Metrics to track
interface AgentMetrics {
    requests: number;
    errors: number;
    avgResponseTime: number;
    toolUsage: Record<string, number>;
    costUSD: number;
}

async function trackMetrics(message, metrics: AgentMetrics) {
    if ('error' in message) {
        metrics.errors++;
    }

    if ('result' in message) {
        metrics.requests++;
    }

    if ('tool_use' in message) {
        const tool = message.tool_use.name;
        metrics.toolUsage[tool] = (metrics.toolUsage[tool] || 0) + 1;
    }

    // Alert on anomalies
    if (metrics.errors / metrics.requests > 0.1) {
        await sendAlert('High error rate detected');
    }
}
```

### CI/CD Integration

Integrate agents into your CI/CD pipeline:

```yaml
# .github/workflows/ai-review.yml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Claude Code Review
        uses: anthropics/claude-code-action@v1
        with:
          api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            Review this pull request for:
            1. Security vulnerabilities
            2. Performance issues
            3. Test coverage gaps
            4. Code quality concerns

            Provide actionable feedback with specific line numbers.

          agents: |
            {
              "security-reviewer": {
                "description": "Security-focused review",
                "tools": ["Read", "Grep", "Glob"]
              }
            }

      - name: Post Review Comment
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: process.env.REVIEW_RESULT
            })
```

---

## Practical Implementation Guide

### Setting Up Your First Agent Harness

#### Step 1: Create Project Instructions

Create `.claude/CLAUDE.md`:

```markdown
# Project Context for Claude

## Project Overview
This is a [Node.js/Python/Go] project that [brief description].

Key technologies:
- Framework: [Express/FastAPI/Gin]
- Database: [PostgreSQL/MongoDB/Redis]
- Testing: [Jest/pytest/testing]

## Architecture
See @ARCHITECTURE.md for detailed architecture documentation.

Key patterns:
- [Pattern 1]: [Brief explanation]
- [Pattern 2]: [Brief explanation]

## Coding Standards

### [Language] Rules
- MUST [critical requirement]
- SHOULD [recommended practice]
- MUST NOT [prohibited pattern]

### Testing Requirements
- MUST achieve [X]% coverage on [layer]
- MUST test [critical scenarios]
- SHOULD use [testing pattern]

## Common Commands

```bash
[command]  # [Description]
[command]  # [Description]
```

## Security Requirements
- MUST [security requirement]
- MUST validate [input type]
- MUST use [security mechanism]
```

#### Step 2: Create Specialized Subagents

Create `.claude/agents/code-reviewer/AGENT.md`:

```markdown
---
name: code-reviewer
description: Expert code reviewer for quality, security, and performance. Use when reviewing code, checking quality, or before merging PRs.
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: default
---

# Code Reviewer Subagent

## Your Role
You are an expert code reviewer ensuring high-quality, secure, maintainable code.

## When to Use
- Before merging pull requests
- After completing a feature
- When requested: "review this code"
- Proactively after significant changes

## Review Process
1. Run `git diff` to see changes
2. Read modified files completely
3. Check for issues in categories below
4. Provide actionable feedback

## Review Categories

### Code Quality
- MUST check for code clarity and readability
- MUST verify proper naming conventions
- SHOULD suggest refactoring for complex code
- SHOULD check for code duplication

### Security
- MUST check for hardcoded credentials
- MUST verify input validation
- MUST check for injection vulnerabilities
- MUST verify proper error handling

### Performance
- SHOULD identify obvious performance issues
- SHOULD check for N+1 queries
- SHOULD verify efficient algorithms

### Testing
- MUST verify tests exist for new functionality
- SHOULD check test coverage of edge cases
- SHOULD verify tests are meaningful

## Output Format

Present review as:

**Summary**: [High-level assessment]

**Critical Issues**: [Must fix before merging]
- [Issue with file:line reference]

**Suggestions**: [Improvements to consider]
- [Suggestion with file:line reference]

**Positive Notes**: [What was done well]
```

#### Step 3: Configure Permissions

Create `.claude/settings.json`:

```json
{
  "permissionMode": "acceptEdits",
  "permissions": {
    "allow": [
      "tool:Read",
      "tool:Grep",
      "tool:Glob",
      "tool:TodoWrite",
      "bash:git status",
      "bash:git log",
      "bash:git diff",
      "bash:npm test",
      "bash:npm run lint"
    ],
    "deny": [
      "bash:rm -rf",
      "bash:sudo *",
      "bash:git push --force",
      "bash:npm publish"
    ]
  },
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "npm run format $FILE_PATH"
          }
        ]
      }
    ]
  }
}
```

#### Step 4: Create Workflow Documentation

Create `.claude/rules/workflow.md`:

```markdown
---
paths: "**/*"
---

# Development Workflow

## Starting a Task
1. Read TODO.md for current context
2. Understand requirements fully before coding
3. Identify files that need changes
4. Draft approach for non-trivial changes

## During Development
- MUST run tests after each logical change
- MUST fix tests before proceeding
- SHOULD commit working increments
- SHOULD update TODO.md with progress

## Completing a Task
- MUST verify all tests pass
- MUST run linter and fix issues
- MUST update documentation if needed
- MUST mark TODO item complete
- SHOULD create meaningful commit message

## Pull Requests
- MUST use code-reviewer subagent before creating PR
- MUST address all critical issues from review
- SHOULD address suggestions from review
- MUST write descriptive PR description
```

#### Step 5: Test Your Harness

```bash
# Test with a simple query
claude --dry-run "What's the current status of the project?"

# Test with a code task
claude "Add input validation to the login endpoint"

# Test subagent invocation
claude "Review the authentication module for security issues"

# Verify permissions
claude "Delete all test files"  # Should be blocked
```

---

## Common Pitfalls and Solutions

### Pitfall 1: Too Much Context

**Problem**: Including entire documentation files in CLAUDE.md.

**Symptom**: Slow responses, context limit errors.

**Solution**: Use references and progressive disclosure.

```markdown
❌ BAD: 500 lines of inline documentation

✅ GOOD: References with summaries
See @docs/api-guide.md for complete API documentation.
Key endpoints: /auth/login, /users, /projects
```

### Pitfall 2: Vague Instructions

**Problem**: Instructions like "write good code" or "follow best practices".

**Symptom**: Inconsistent behavior, doesn't match expectations.

**Solution**: Be specific and actionable.

```markdown
❌ BAD: "Write good TypeScript code"

✅ GOOD:
- MUST use explicit return types
- MUST enable strict mode
- MUST use const by default
```

### Pitfall 3: Over-Permissioning

**Problem**: Granting all tools by default.

**Symptom**: Unnecessary tool usage, security risks.

**Solution**: Grant minimum necessary tools.

```json
❌ BAD: allowedTools: ["*"]

✅ GOOD: allowedTools: ["Read", "Grep"]  // For read-only tasks
```

### Pitfall 4: No Session Continuity

**Problem**: No artifacts between sessions.

**Symptom**: Agent starts from scratch each time, repeated work.

**Solution**: Design for discrete sessions with persistent artifacts.

```markdown
✅ GOOD: Session management
- TODO.md tracks current work
- PROGRESS.md documents what's done
- Git commits provide history
- ARCHITECTURE.md captures decisions
```

### Pitfall 5: Insufficient Testing

**Problem**: No validation of agent behavior.

**Symptom**: Unreliable in production, unexpected failures.

**Solution**: Build evaluation framework.

```python
✅ GOOD: Test agent with scenarios
test_cases = [
    {'input': 'Add login endpoint', 'expected': 'Uses bcrypt for passwords'},
    {'input': 'Create user table', 'expected': 'Has email unique constraint'},
]
```

### Pitfall 6: Ignoring Cost

**Problem**: Inefficient prompts and tool usage.

**Symptom**: High API costs.

**Solution**: Monitor and optimize.

```typescript
✅ GOOD: Track costs
- Log input/output tokens per request
- Monitor tool usage patterns
- Set budget alerts
- Optimize inefficient patterns
```

---

## Summary: Key Takeaways

### ✅ DO

1. **Keep instructions concise and scannable**
   - Use RFC 2119 keywords (MUST, SHOULD, MAY)
   - Use flat bullet lists
   - Be specific and actionable

2. **Grant minimal permissions**
   - Only tools needed for the task
   - Use permissionMode appropriately
   - Block dangerous operations

3. **Design for multi-session continuity**
   - Persistent artifacts (TODO.md, PROGRESS.md)
   - Meaningful git commits
   - Clear handoff between sessions

4. **Use specialized subagents**
   - Focused expertise
   - Isolated context
   - Restricted tool access

5. **Validate and test**
   - Evaluation datasets
   - Regression testing
   - Audit logging

### ❌ DON'T

1. **Don't inline large documentation**
   - Use references (@docs/file.md)
   - Progressive disclosure

2. **Don't be vague**
   - "Write good code" → "MUST use TypeScript strict mode"
   - "Be careful" → "MUST validate user inputs with class-validator"

3. **Don't over-permission**
   - Grant minimum necessary tools
   - Use deny lists for dangerous operations

4. **Don't skip security**
   - Validate inputs
   - Audit modifications
   - Rate limit requests

5. **Don't deploy without testing**
   - Test with real scenarios
   - Monitor in production
   - Have rollback plan

---

## Further Reading

### Official Documentation
- [Claude Code Documentation](https://code.claude.com/docs)
- [Claude Agent SDK](https://platform.claude.com/docs/en/agent-sdk)
- [Agent Rules Specification](https://agents.md/)
- [RFC 2119: Keyword Definitions](https://www.rfc-editor.org/rfc/rfc2119)

### Research and Best Practices
- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Anthropic: Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Anthropic: Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [UiPath: 10 Best Practices for Building Reliable AI Agents](https://www.uipath.com/blog/ai/agent-builder-best-practices)
- [GitHub: How to Write a Great AGENTS.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [Builder.io: Improve Your AI Code Output with AGENTS.md](https://www.builder.io/blog/agents-md)
- [PubNub: Best Practices for Claude Code Subagents](https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/)

### Community Resources
- [Claude Agent Skills Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
- [ClaudeLog: Agent-First Design](https://claudelog.com/mechanics/agent-first-design/)
- [Minusx: What Makes Claude Code So Damn Good](https://minusx.ai/blog/decoding-claude-code/)

---

**Document Version**: 1.0
**Last Updated**: 2025-12-31
**Maintainer**: Generated by Claude Code research
