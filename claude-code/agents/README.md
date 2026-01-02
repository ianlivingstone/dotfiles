# Claude Code Agents Directory

This directory contains specialized subagents for this project.

## Available Agents

### harness-architect
**Purpose**: Expert in agent harness design and Claude Code configuration.

**Use When**:
- Creating new subagents
- Reviewing CLAUDE.md or AGENTS.md files
- Improving agent instructions
- Designing .claude/settings.json configurations
- Optimizing context usage
- Auditing harness security

**Example Usage**:
```
> Review my CLAUDE.md file for Agent Rules compliance
> Create a subagent for validating shell scripts
> Improve the instructions in shell/AGENTS.md
> Audit .claude/settings.json for security issues
> Design a multi-agent workflow for PR reviews
```

**Key Features**:
- Understands Agent Rules specification (RFC 2119)
- Validates Claude Code best practices
- Provides structured, actionable feedback
- Creates production-ready subagent files
- Optimizes for context efficiency
- Ensures security compliance

**Trigger Phrases**:
- "review", "audit", "improve" + harness/agent/CLAUDE.md
- "create subagent", "design agent"
- "optimize context", "improve instructions"
- "check security", "validate permissions"

## Agent Design Guidelines

When creating new subagents for this directory:

### 1. File Structure
```
.claude/agents/
├── README.md                    # This file
├── agent-name.md               # Subagent definition
└── examples/                   # Optional examples directory
    └── agent-name-example.md
```

### 2. Naming Convention
- Use kebab-case: `security-auditor.md`, `test-runner.md`
- Be descriptive: `code-reviewer.md` not `reviewer.md`
- Indicate purpose: `bash-validator.md`, `git-helper.md`

### 3. Required Structure
```markdown
---
name: agent-name
description: Clear purpose with trigger phrases. Use when [scenarios].
tools: [Minimal necessary tools]
model: sonnet|haiku
permissionMode: default|acceptEdits
---

# Agent Name

## Your Role
[What this agent does]

## When to Use
[Specific scenarios]

## Process
1. [Step 1]
2. [Step 2]

## Requirements
- MUST [requirement]
- SHOULD [recommendation]
- MUST NOT [prohibition]
```

### 4. Agent Rules Compliance
- ✅ Use RFC 2119 keywords (MUST, SHOULD, MAY)
- ✅ Use imperative statements
- ✅ Flat bullet list format
- ✅ Specific and actionable
- ✅ Include trigger phrases in description

### 5. Tool Selection
**Read-only agents** (Haiku):
```yaml
tools: Read, Grep, Glob
model: haiku
permissionMode: default
```

**Analysis agents** (Sonnet):
```yaml
tools: Read, Grep, Glob, Bash
model: sonnet
permissionMode: default
```

**Action agents** (Sonnet):
```yaml
tools: Read, Write, Edit, Bash
model: sonnet
permissionMode: acceptEdits
```

## Using Agents

### Explicit Invocation
```
> Use the harness-architect agent to review my CLAUDE.md
> Have the security-auditor check this bash script
```

### Automatic Delegation
Claude will automatically use agents when trigger phrases match:
```
> Review my agent configuration
  → Triggers harness-architect (contains "review" + "agent")

> Audit this for security issues
  → Triggers security-auditor (contains "audit" + "security")
```

### Resume Previous Agent
```
> Resume agent abc123 and now check the hooks configuration too
```

## Best Practices

### DO
- ✅ Create focused, single-purpose agents
- ✅ Use minimal necessary tools
- ✅ Include natural trigger phrases
- ✅ Follow Agent Rules format
- ✅ Test agents before committing

### DON'T
- ❌ Create one agent that does everything
- ❌ Grant all tools by default
- ❌ Use vague descriptions
- ❌ Skip the YAML frontmatter
- ❌ Inline large documentation

## Testing New Agents

Before committing a new agent:

1. **Syntax check**:
   ```bash
   # Verify YAML frontmatter parses
   claude --dry-run "Use my-new-agent to test"
   ```

2. **Functional test**:
   ```bash
   # Test with actual task
   claude "Use my-new-agent to [specific task]"
   ```

3. **Trigger test**:
   ```bash
   # Test automatic delegation
   claude "[phrase that should trigger agent]"
   ```

4. **Security review**:
   ```bash
   # Use harness-architect to review
   claude "Review .claude/agents/my-new-agent.md for security"
   ```

## Resources

- [Agent Rules Specification](https://agents.md/)
- [RFC 2119 Keywords](https://www.rfc-editor.org/rfc/rfc2119)
- [Claude Code Docs](https://code.claude.com/docs)
- [Best Practices Guide](../docs/AGENT-HARNESS-BEST-PRACTICES.md)

## Contributing

When adding new agents to this directory:

1. Follow the guidelines above
2. Use `harness-architect` to review your agent
3. Test thoroughly
4. Update this README with the new agent
5. Commit with descriptive message

## Questions?

Use the `harness-architect` agent:
```
> I want to create an agent for [purpose]. Help me design it.
> Review my agent design for best practices.
> How should I structure a subagent for [use case]?
```
