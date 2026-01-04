---
description: Validate AGENTS.md files for Agent Rules specification compliance
---

Validate AGENTS.md files against the Agent Rules specification.

This command checks for:
- RFC 2119 keyword usage (MUST, SHOULD, MAY, etc.)
- Imperative statement format (not "you should" but "MUST")
- Clear section structure with markdown headers
- Common anti-patterns

The validation runs automatically via PostToolUse hook when editing AGENTS.md files.

## Manual Usage

```bash
~/.claude/commands/validate-agent-rules.sh path/to/AGENTS.md
```

## What It Checks

**RFC 2119 Keywords:**
- Files should use MUST, SHOULD, MAY, MUST NOT, SHOULD NOT
- Provides clear, unambiguous guidance

**Imperative Statements:**
- ✅ Good: "MUST validate input before use"
- ❌ Bad: "You should validate input before use"

**Anti-Patterns:**
- Question-style guidance ("Should you validate?")
- Non-imperative statements ("It is recommended to...")
- Vague language ("Consider validating...")

## References

- Agent Rules specification: docs/quality/documentation-standards.md
- RFC 2119: https://www.rfc-editor.org/rfc/rfc2119
