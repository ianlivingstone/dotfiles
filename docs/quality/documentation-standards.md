# Documentation Standards

## Agent Rules Compliance

All AI agent guidance files MUST follow the Agent Rules specification.

### MUST use imperative statements
```markdown
✅ GOOD: "Update the file"
❌ BAD: "You should update the file"

✅ GOOD: "Read docs/security/patterns.md"
❌ BAD: "You might want to read docs/security/patterns.md"
```

### MUST use RFC 2119 keywords for clarity
- **MUST** - Required, no exceptions
- **MUST NOT / NEVER** - Forbidden, no exceptions
- **SHOULD** - Recommended, exceptions allowed with justification
- **SHOULD NOT** - Not recommended, but allowed with justification
- **MAY** - Optional, user's choice

Examples:
```markdown
✅ GOOD: "MUST quote all variables in shell scripts"
✅ GOOD: "SHOULD use XDG directories for configs"
✅ GOOD: "MAY use custom target for packages"

❌ BAD: "It's important to quote variables"
❌ BAD: "You really should use XDG directories"
❌ BAD: "You can use custom targets if you want"
```

### MUST structure as flat bullet lists for scannability
```markdown
✅ GOOD:
- MUST quote all variables
- MUST validate user input
- MUST set correct permissions
- SHOULD use XDG directories

❌ BAD:
When working with shell scripts, you should always make sure to quote
your variables properly. This is important because unquoted variables
can lead to word splitting and glob expansion issues. You also need to
validate user input before using it in commands.
```

### MUST be concise and actionable
```markdown
✅ GOOD:
- MUST validate input: `[[ "$input" =~ ^[a-z]+$ ]]`
- MUST quote variables: `cat "$file"`

❌ BAD:
- You should probably validate the input that users provide to make
  sure it's safe before you use it in any commands, otherwise bad
  things might happen.
```

### SHOULD reference comprehensive documentation files for details
```markdown
✅ GOOD:
For detailed shell patterns:
- Read docs/development/shell-patterns.md

❌ BAD:
[Duplicates 200 lines of shell patterns inline]
```

## Documentation Maintenance Rules

### When Making Changes

**MUST update the component's AGENTS.md file when modifying that component:**
- Modified shell script → Update shell/AGENTS.md
- Modified Git config → Update git/AGENTS.md
- Modified Neovim config → Update nvim/AGENTS.md

**MUST update integration sections in related component AGENTS.md files for cross-component changes:**
- Changed shell module loading → Update shell/AGENTS.md
- Changed how Git integrates with shell → Update both git/AGENTS.md and shell/AGENTS.md

**MUST update ARCHITECTURE.md for high-level architectural changes:**
- Changed package management strategy
- Modified security architecture
- Added new cross-cutting concern

**MUST update docs/ files for pattern changes:**
- New security pattern → Update docs/security/patterns.md
- New development workflow → Update docs/development/
- New testing approach → Update docs/development/testing-debugging.md

**MUST verify all documentation links still work after changes:**
```bash
# Check all markdown links
grep -r '\[.*\](.*\.md)' docs/ | while read line; do
    # Extract file path
    # Verify file exists
done
```

**SHOULD include code examples that follow established patterns:**
```markdown
✅ GOOD:
```bash
# ✅ GOOD: Properly quoted
cat "$file_path"

# ❌ BAD: Unquoted
cat $file_path
```

❌ BAD:
Make sure to quote your variables properly in shell scripts.
```

## Documentation Standards by File Type

### CLAUDE.md
- 200 lines maximum
- Quick reference and navigation
- Essential rules only
- Links to detailed docs/
- No duplicated content from docs/

### AGENTS.md (Component)
- Component-specific implementation
- Integration points
- Technical details
- 100-200 lines typical
- Agent Rules compliant

### docs/ Files
- Detailed guidance (100-200 lines per file)
- Comprehensive examples
- Cross-references to related docs
- Task-oriented organization
- Agent Rules compliant

### ARCHITECTURE.md
- High-level design principles
- Architectural decisions and rationale
- Component relationships
- Design philosophy
- 200-300 lines

### README.md
- User-facing documentation
- Features and benefits
- Quick start guide
- Installation instructions
- Usage examples

## What Goes Where

### CLAUDE.md (200 lines)
- Project overview
- Quick reference map
- Essential rules
- Decision tree for finding information
- Links to docs/ for details

### docs/ (detailed, organized by topic)
- Comprehensive development patterns
- Security guidelines with examples
- Architecture deep-dives
- Testing strategies
- Feature development workflow

### ARCHITECTURE.md
- High-level design principles
- Why architectural decisions were made
- Component relationships
- Design philosophy

### Component AGENTS.md
- Component-specific implementation
- Integration points with other components
- Technical implementation details

### README.md
- User documentation
- Feature descriptions
- Installation and usage
- Troubleshooting
- Examples

## Documentation Update Workflow

### Planning Phase
1. Review existing docs to understand current state
2. Note which docs need updates
3. Don't update yet - wait for plan approval

### Implementation Phase
1. Update code
2. Update technical docs (AGENTS.md, docs/)
3. Update user-facing docs (README.md)
4. Update architecture docs if needed
5. Verify all links work
6. Commit docs with code changes

### Example Update Order
```markdown
## Recommendation X.X: Add New Feature

**Documentation Impact**:
1. Implement feature code
2. Update component AGENTS.md (technical details)
3. Update docs/development/ (development patterns)
4. Update CLAUDE.md (if cross-cutting pattern)
5. Update README.md (user-facing feature)
6. Update ARCHITECTURE.md (if architectural change)
7. Verify all cross-references work
8. Commit all together
```

## Documentation Quality Checklist

Before committing documentation:
- [ ] Follows Agent Rules specification
- [ ] Uses RFC 2119 keywords correctly
- [ ] Imperative statements (not "you should")
- [ ] Flat bullet list format
- [ ] Concise and actionable
- [ ] Code examples included
- [ ] Examples show good and bad patterns
- [ ] Cross-references work
- [ ] Appropriate location (CLAUDE.md vs docs/ vs AGENTS.md)
- [ ] No duplicated content
- [ ] Accurate and current

## Documentation Anti-Patterns

### Don't duplicate content
```markdown
❌ BAD:
# CLAUDE.md (1433 lines)
[200 lines of GNU Stow documentation]

# docs/development/package-management.md
[Same 200 lines of GNU Stow documentation]
```

```markdown
✅ GOOD:
# CLAUDE.md (200 lines)
For GNU Stow package management:
- Read docs/development/package-management.md

# docs/development/package-management.md (250 lines)
[Comprehensive GNU Stow documentation]
```

### Don't use generic advice
```markdown
❌ BAD:
"Make sure your code is clean and well-organized"

✅ GOOD:
"MUST follow single responsibility principle for functions"
```

### Don't leave outdated examples
```markdown
❌ BAD:
# Example using old API that no longer exists

✅ GOOD:
# Example using current API
# Updated: 2026-01-03
```

### Don't bury important information
```markdown
❌ BAD:
[1000 lines of background]
Important security requirement buried on line 847

✅ GOOD:
## Security Requirements (top of file)
- MUST validate all user input
- MUST quote all variables
```

## Cross-References

- docs/architecture/documentation-strategy.md (Overall strategy)
- CLAUDE.md (Primary context file)
- ARCHITECTURE.md (High-level design)
