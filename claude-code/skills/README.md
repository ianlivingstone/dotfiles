# Claude Code Skills

This directory contains **global skills** that are available across all projects.

## What Are Skills?

Skills are automatically-discovered capabilities that Claude applies based on context. Unlike slash commands (which you invoke explicitly with `/command`), skills are triggered when Claude detects you need them based on the skill's description.

**Key differences from commands:**
- **Discovery**: Skills are auto-suggested, commands are manually invoked
- **Complexity**: Skills can include multiple files and supporting docs
- **Structure**: Skills use a directory with `SKILL.md`, commands are single `.md` + `.sh` files

## Available Skills

### pr-review
**Comprehensive GitHub pull request review and analysis**

**Use when:**
- Checking PR status or readiness
- Finding merge blockers
- Reviewing CI/CD checks
- Assessing unresolved comments
- Evaluating PR health metrics

**What it does:**
1. Fetches comprehensive PR data using GitHub CLI
2. Analyzes merge blockers (conflicts, failing checks, draft status)
3. Reviews unresolved comments and discussions
4. Assesses PR against best practices
5. Provides actionable next steps

**Example usage:**
```
Review PR #123
What's blocking my PR?
Is this PR ready to merge?
Check the status of pull request https://github.com/org/repo/pull/456
```

**Requires:**
- GitHub CLI (`gh`) installed and authenticated
- Being in a repository or providing PR URL/number

**Documentation:**
- `pr-review/SKILL.md` - Main skill instructions
- `pr-review/best-practices.md` - Research-backed PR best practices
- `pr-review/examples.md` - Sample outputs for common scenarios

---

## Creating New Skills

See [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills.md) for details.

### Quick Start

1. **Create skill directory:**
   ```bash
   mkdir -p claude-code/skills/my-skill-name
   ```

2. **Create SKILL.md with frontmatter:**
   ```yaml
   ---
   name: my-skill-name
   description: Clear description of when to use this skill
   allowed-tools: Bash, Read, Write  # Optional: restrict tools
   ---

   # Skill instructions here
   ```

3. **Add supporting files (optional):**
   ```
   my-skill/
   ├── SKILL.md (required)
   ├── reference.md (optional)
   └── examples.md (optional)
   ```

4. **Reinstall dotfiles to stow:**
   ```bash
   ./dotfiles.sh reinstall
   ```

5. **Verify skill loaded:**
   Start new Claude Code session and ask: "What skills are available?"

### Skill Guidelines

**MUST:**
- Keep SKILL.md under 500 lines (use supporting files for details)
- Write clear, specific descriptions for auto-discovery
- Include concrete trigger phrases users would naturally say
- Provide step-by-step instructions for Claude
- Handle errors gracefully with helpful messages

**SHOULD:**
- Use progressive disclosure (link to supporting docs)
- Include examples of expected output
- Restrict tools if skill should be read-only
- Test skill with various phrasings
- Document prerequisites clearly

**Description tips:**
- Include action verbs: "reviews", "analyzes", "checks"
- Mention specific triggers: "PR", "pull request", "merge blockers"
- Explain WHAT and WHEN clearly
- Keep under 1024 characters

---

## Skills vs Commands vs Agents

### When to use Skills
- Complex workflows Claude should discover automatically
- Multi-step processes with supporting documentation
- Context-dependent capabilities
- Tools with multiple modes/options

### When to use Commands (slash commands)
- Quick, explicit operations you invoke manually
- Simple prompts or templates
- Tasks you do frequently the same way
- Single-file prompts

### When to use Agents
- Complex, multi-step tasks requiring decision-making
- Planning and architectural design
- Tasks needing extensive codebase context
- Specialized domain expertise (security, shell validation, etc.)

**Available in this harness:**
- **Skills**: Global capabilities (this directory)
- **Commands**: `claude-code/commands/` - Global slash commands
- **Agents**: `claude-code/agents/` - Specialized sub-agents

---

## Skill Installation

Skills in `claude-code/skills/` are stowed to `~/.claude/skills/` via:

```bash
# Stow configuration in packages.config
claude-code:$HOME/.claude
```

After modifying skills:
```bash
./dotfiles.sh reinstall  # Restows all packages including claude-code
```

Skills are loaded automatically when Claude Code starts.

---

## Testing Skills

### 1. Verify Skill Installed
```bash
ls -la ~/.claude/skills/my-skill-name/
```

### 2. Check Skill Loaded
Start Claude Code and ask:
```
What skills are available?
```

### 3. Test Trigger Phrases
Try various phrasings that should match your skill's description:
```
# For pr-review skill:
Review PR #123
What's blocking my pull request?
Is this PR ready to merge?
```

### 4. Verify Tool Restrictions
If you set `allowed-tools`, try using a restricted tool and verify it's blocked.

### 5. Test Error Handling
Try invalid inputs to ensure errors are handled gracefully.

---

## Troubleshooting

### Skill not loading
```bash
# Check file exists
ls ~/.claude/skills/my-skill/SKILL.md

# Check frontmatter syntax
head -20 ~/.claude/skills/my-skill/SKILL.md

# Reinstall
./dotfiles.sh reinstall
```

### Skill not triggering
- Check description is specific and includes trigger terms
- Try exact phrases from description
- Verify skill name doesn't conflict with another skill
- Check Claude Code output for skill loading errors

### Tool restrictions not working
- Verify `allowed-tools` is spelled correctly in frontmatter
- Check tool names match exactly (case-sensitive)
- Restart Claude Code after changes

---

## References

**Related documentation:**
- `claude-code/commands/README.md` - Slash commands
- `claude-code/agents/README.md` - Specialized agents
- `docs/development/claude-code-integration.md` - Claude Code integration guide
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills.md)

**External resources:**
- [Claude Code Official Docs](https://code.claude.com/docs/)
- [GitHub CLI Documentation](https://cli.github.com/manual/)

---

**Last Updated:** 2026-01-04
**Skills Count:** 1 (pr-review)
