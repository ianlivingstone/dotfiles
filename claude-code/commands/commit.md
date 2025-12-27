---
description: Generate commit message and commit staged changes
---

# Commit Workflow

Create commits with AI-generated messages and intelligent GPG handling.

## Usage

```bash
# 1. Get commit context and guidelines
~/.claude/commands/commit.sh

# 2. Pipe commit message directly to commit command
cat <<'EOF' | ~/.claude/commands/commit.sh commit
Your commit message here

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
```

**Alternative:** Pass message via file
```bash
~/.claude/commands/commit.sh commit /path/to/message.txt
```

The script handles GPG signing detection automatically. If passphrase is cached, commits proceed automatically. If not, instructions are provided. No temporary files needed when using stdin!
