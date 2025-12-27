---
description: Generate commit message and commit staged changes
---

# Commit Workflow

Create commits with AI-generated messages and intelligent GPG handling.

## Usage

```bash
# 1. Get commit context and guidelines
~/.claude/commands/commit.sh

# 2. Generate unique filename
COMMIT_FILE=$(~/.claude/commands/commit.sh generate-filename)

# 3. Write commit message to file
# (Claude writes the message based on staged changes)

# 4. Commit with the message
~/.claude/commands/commit.sh commit $COMMIT_FILE
```

The script handles GPG signing detection automatically. If passphrase is cached, commits proceed automatically. If not, instructions are provided.
