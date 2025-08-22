# Claude Code Hooks Architecture

**📋 Agent Rules Compliance**: This file follows Agent Rules specification using imperative statements with RFC 2119 keywords (MUST, SHOULD, MAY, NEVER) and flat bullet list format for AI coding agents.

## Hook System Architecture

### Core Design Principles

- **Single Responsibility**: Each hook MUST focus on one specific task (whitespace, formatting, validation, etc.)
- **Non-Blocking**: Hook failures MUST NOT prevent Claude Code from functioning
- **Performance First**: Hooks MUST complete quickly to avoid slowing the edit cycle
- **Safe Operations**: Hooks MUST NEVER corrupt or delete user files unintentionally
- **Modular Design**: Each hook is an independent Rust crate with its own dependencies

### Hook Lifecycle

- **Trigger**: PostToolUse event fires after Write/Edit/MultiEdit operations
- **Environment**: Claude Code provides file paths and context via environment variables
- **Execution**: Each matched hook runs as a separate process
- **Output**: Hook output appears in Claude Code transcript (Ctrl+R)
- **Completion**: Exit code determines success (0) or failure (non-zero)

### Directory Structure

```
claude_hooks/
├── bin/                        # Compiled hook binaries (excluded from git)
├── hooks/                      # Individual hook source code
│   └── whitespace-cleaner/     # Current: whitespace cleanup hook
├── lib/                        # Future: shared Rust workspace
├── build-hooks.sh              # Build automation script
├── README.md                   # User documentation
└── AGENTS.md                   # This file - AI agent architecture guide
```

## Hook Development Rules

### File Structure Requirements

- MUST create each hook as a separate Rust crate in `hooks/` directory
- MUST include `Cargo.toml` with appropriate metadata and dependencies
- MUST implement `main()` function as the entry point
- SHOULD use `clap` for command-line argument parsing if needed
- SHOULD include error handling for all file operations

### Environment Variables

Claude Code hooks receive these environment variables:

- **CLAUDE_FILE_PATHS**: Colon-separated list of file paths that were modified
- **CLAUDE_TOOL_OUTPUT**: Output from the preceding Claude Code tool
- **CLAUDE_PROJECT_DIR**: Current working directory of the Claude Code session

### Error Handling Patterns

- MUST exit with code 0 on successful processing
- MUST exit with non-zero code on critical failures
- MUST handle file not found gracefully (not an error)
- SHOULD log errors to stderr with descriptive messages
- NEVER panic or crash on expected error conditions
- SHOULD skip processing files that cannot be read safely

### File Processing Standards

- MUST check file existence before attempting to read
- MUST preserve file permissions and ownership when possible
- MUST handle empty files gracefully
- SHOULD detect and skip binary files when appropriate
- MUST use atomic write operations to prevent data loss
- SHOULD maintain original file timestamps when content unchanged

### Performance Requirements

- MUST complete processing within 5 seconds for typical files
- SHOULD optimize for common cases (text files under 1MB)
- MUST avoid loading entire large files into memory when possible
- SHOULD implement early exit for files that don't need processing
- NEVER perform expensive operations like network requests

## Hook Integration Patterns

### Claude Code Configuration

Hooks integrate via `.claude/settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "claude_hooks/bin/hook-name",
            "description": "Hook purpose description"
          }
        ]
      }
    ]
  }
}
```

### Build System Integration

- MUST update `build-hooks.sh` when adding new hooks
- MUST ensure binary names match directory names for consistency
- SHOULD copy compiled binaries to `claude_hooks/bin/` directory
- MUST handle missing source directories gracefully in build script

### Status Reporting Integration

The dotfiles status system checks hooks:

- **Built and up to date**: Source older than binary, shows ✅
- **Needs rebuild**: Source newer than binary, shows ⚠️
- **Binary not found**: No compiled binary exists, shows ❌

## Hook Implementation Patterns

### Basic Hook Template

```rust
use std::env;
use std::fs;
use std::path::Path;

fn main() {
    let file_paths = env::var("CLAUDE_FILE_PATHS").unwrap_or_default();
    
    for file_path in file_paths.split(':') {
        if file_path.is_empty() {
            continue;
        }
        
        match process_file(file_path) {
            Ok(changed) => {
                if changed {
                    println!("✅ Processed {}", file_path);
                }
            },
            Err(e) => {
                eprintln!("❌ Error processing {}: {}", file_path, e);
            }
        }
    }
}

fn process_file(file_path: &str) -> Result<bool, Box<dyn std::error::Error>> {
    let path = Path::new(file_path);
    
    // Skip non-existent files
    if !path.exists() {
        return Ok(false);
    }
    
    // Skip binary files if needed
    if is_binary_file(path)? {
        return Ok(false);
    }
    
    let original_content = fs::read_to_string(path)?;
    let processed_content = your_processing_logic(&original_content);
    
    if processed_content != original_content {
        fs::write(path, processed_content)?;
        return Ok(true);
    }
    
    Ok(false)
}
```

### Whitespace Cleaner Architecture

The current whitespace-cleaner hook demonstrates these patterns:

- **Environment parsing**: Reads `CLAUDE_FILE_PATHS` and splits on colons
- **File validation**: Checks existence before processing
- **Content processing**: Removes trailing whitespace from each line
- **Conditional writing**: Only writes if content actually changed
- **User feedback**: Provides emoji-based status indicators

## Future Hook Architecture

### Planned Hook Types

- **file-formatter**: Language-specific code formatting
- **security-scanner**: Credential and vulnerability detection
- **git-integrator**: Pre-commit hooks and auto-staging
- **doc-generator**: Auto-update documentation from code

### Shared Library Architecture

Future shared crate (`lib/claude-common/`) should provide:

- **File utilities**: Common file operations, binary detection, atomic writes
- **Error handling**: Standardized error types and reporting
- **Environment parsing**: Unified environment variable handling
- **Logging**: Consistent output formatting with emoji indicators
- **Configuration**: Shared configuration file parsing

### Workspace Configuration

Future `lib/Cargo.toml` workspace root:
```toml
[workspace]
members = [
    "claude-common",
    "../hooks/whitespace-cleaner",
    "../hooks/file-formatter",
    "../hooks/security-scanner"
]

[workspace.dependencies]
clap = "4.0"
serde = "1.0"
tokio = "1.0"
```

## Hook Execution Environment

### Security Considerations

- Hooks run with same permissions as Claude Code process
- MUST validate file paths to prevent directory traversal attacks
- SHOULD sanitize any user input from environment variables
- NEVER execute arbitrary commands from file content
- MUST handle malformed or malicious file content safely

### Error Recovery Patterns

- Individual hook failures MUST NOT affect other hooks
- Claude Code continues normally even if all hooks fail
- Hook output appears in transcript but doesn't interrupt user workflow
- Failed hooks should provide actionable error messages

### Testing Requirements

- MUST test hooks with various file types and sizes
- SHOULD test with edge cases (empty files, binary files, permissions)
- MUST verify hooks work correctly in different directories
- SHOULD test error conditions and recovery patterns
- MUST ensure hooks don't modify files unnecessarily

## Integration with Dotfiles System

### Build System Integration

- `./dotfiles.sh install` automatically builds hooks via `build_hooks()`
- `./dotfiles.sh update` rebuilds hooks if source is newer than binaries
- `./dotfiles.sh status` shows hook build status alongside other tools
- Build failures are reported but don't stop installation

### Configuration Management

- Hook configuration stored in `.claude/settings.json` (committed to repo)
- No machine-specific hook configuration currently needed
- Hooks should work identically across all development machines
- Future: hook-specific config files in `claude_hooks/config/`

This architecture ensures hooks remain modular, performant, and safe while providing powerful automation for Claude Code workflows.