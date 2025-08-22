#!/usr/bin/env zsh
set -euo pipefail

# Build all Claude Code hooks and install binaries to claude_hooks/bin/

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")" && pwd)"
BIN_DIR="$HOOKS_DIR/bin"
HOOKS_SRC_DIR="$HOOKS_DIR/hooks"

echo "🔧 Building Claude Code hooks..."

# Ensure bin directory exists
mkdir -p "$BIN_DIR"

# Build whitespace cleaner hook
if [[ -d "$HOOKS_SRC_DIR/whitespace-cleaner" ]]; then
    echo "📦 Building whitespace-cleaner..."
    cd "$HOOKS_SRC_DIR/whitespace-cleaner"
    cargo build --release
    
    # Copy binary to bin directory
    cp target/release/claude-hook-processor "$BIN_DIR/whitespace-cleaner"
    echo "✅ whitespace-cleaner → claude_hooks/bin/"
else
    echo "⚠️  whitespace-cleaner source not found in $HOOKS_SRC_DIR/whitespace-cleaner"
fi

echo "🎉 Build complete! Claude Code hook binaries available in claude_hooks/bin/"