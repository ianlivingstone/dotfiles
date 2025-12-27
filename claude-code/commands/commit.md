---
description: Generate commit message and commit staged changes
---

# Auto-Commit with Generated Message

Analyzes staged changes and generates commit messages with intelligent GPG handling.

## Instructions

1. Run `~/.claude/commands/commit.sh` to gather commit context
2. Write the commit message to a temporary file
3. Call `~/.claude/commands/commit.sh commit <message-file>` to create the commit

The script will:
- Check if GPG signing is required (via `git config commit.gpgsign`)
- Verify if GPG agent is running and key is available
- If GPG is configured properly: attempt the commit automatically
- If GPG is not ready: save the message and provide manual instructions

## GPG Detection

The script checks:
- Is `commit.gpgsign` enabled in git config?
- Is `gpg-agent` running?
- Is the signing key configured and available?
- Can gpg-agent respond to commands?

**If GPG is working:** The commit happens automatically (passphrase cached in agent)

**If GPG is not working:** Message is saved to file with instructions for manual commit
