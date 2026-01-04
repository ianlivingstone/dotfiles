# GNU Stow Package Management

## Package System Architecture

The dotfiles system uses GNU Stow for symlink management with configuration-driven package definition:

1. **packages.config** - Single source of truth listing all packages and target locations
2. **Package directories** - Self-contained tool configurations in repository root
3. **GNU Stow** - Creates symlinks from package directories to target locations
4. **Stow validation** - Status checking using Stow's own `--no --restow` logic

**Key principle:** Each package directory mirrors the target filesystem structure.

## Adding New Packages

### Step 1: Create package directory
```bash
mkdir mypackage
```

### Step 2: Add configuration files

For files that symlink to `~/` (default target):
```bash
# Directory structure mirrors target:
mypackage/
├── .myconfig       # Will symlink to ~/.myconfig
└── .mytool/        # Will symlink to ~/.mytool/
    └── config.yml
```

For files that symlink to custom locations (e.g., `~/.config/mypackage/`):
```bash
# Directory structure mirrors target:
mypackage/
└── .config/
    └── mypackage/          # Will symlink to ~/.config/mypackage/
        └── config.yml
```

### Step 3: Add to packages.config
```bash
# Default target (~/)
echo "mypackage" >> packages.config

# Custom target (must match directory structure)
echo "mypackage:\$XDG_CONFIG_DIR/mypackage" >> packages.config
```

### Step 4: Test installation
```bash
./dotfiles.sh status        # Verify package detected and would install correctly
./dotfiles.sh reinstall     # Install the package
```

**MUST follow these rules:**
- MUST mirror target directory structure in package directory
- MUST add to packages.config before testing
- MUST test with `status` before `reinstall`
- SHOULD use XDG directories for application configs (`~/.config/`)
- SHOULD use default target (`~/`) for shell configs (`.bashrc`, `.zshrc`, etc.)

## Package Configuration Format

The `packages.config` file uses this format:
```bash
# Format: package[:target]
# Lines starting with # are comments
# Variables are expanded during installation

# Default target examples (symlink to ~/)
git
ssh
tmux
shell

# Custom target examples (symlink to specified location)
nvim:$XDG_CONFIG_DIR/nvim              # → ~/.config/nvim/
gnupg:$HOME/.gnupg                     # → ~/.gnupg/
starship:$XDG_CONFIG_DIR               # → ~/.config/
```

**Available variables:**
- `$HOME` - User's home directory (e.g., `/Users/ian`)
- `$XDG_CONFIG_DIR` - Typically `~/.config` (respects `XDG_CONFIG_HOME`)
- Any other environment variables available during installation

**Format rules:**
- MUST use format `package` or `package:target`
- MUST use `$VAR` syntax for variables (not `${VAR}`)
- MUST ensure target directory exists or will be created
- SHOULD comment out packages instead of deleting (preserves history)
- NEVER commit packages.config with user-specific paths

## Status Validation Logic

The `./dotfiles.sh status` command uses GNU Stow's own validation logic:

**Implementation:**
```bash
# For each package in packages.config:
stow --no --restow --verbose=2 --target="$TARGET" --dir="$REPO" "$PACKAGE" 2>&1

# Parse Stow output to determine status:
# - "LINK: file" means file would be created/updated
# - "UNLINK: file" means file would be removed
# - No LINK/UNLINK output means package is properly installed
```

**Status indicators:**
- ✅ `properly stowed` - All symlinks correct, no changes needed
- ❌ `would make changes` - Shows what Stow would do (LINK/UNLINK operations)
- ⚠️ `missing` - Package directory not found in repository

**MUST understand validation behavior:**
- Validation uses Stow's dry-run mode (`--no` flag)
- Validation is authoritative - shows exactly what `reinstall` would do
- Validation catches conflicts, missing files, incorrect symlinks
- Validation output is actionable - shows specific files that would change

**Testing status checking:**
```bash
# All packages should show properly stowed
./dotfiles.sh status

# Test detection of changes
echo "test" > git/.gitconfig-test
./dotfiles.sh status  # Shows: would make changes: LINK: .gitconfig-test

# Clean up test
rm git/.gitconfig-test
./dotfiles.sh status  # Shows: properly stowed again
```

## Removing Packages

### Step 1: Remove from packages.config
```bash
# Edit packages.config and delete or comment out the line
vim packages.config
# Or: sed -i '' '/^packagename/d' packages.config
```

### Step 2: Reinstall to remove symlinks
```bash
./dotfiles.sh reinstall  # Unstows packages not in packages.config
```

### Step 3: Optionally delete package directory
```bash
rm -rf packagename/  # Only if you don't want it available anymore
```

**MUST follow this order:**
- MUST remove from packages.config BEFORE running reinstall
- MUST run reinstall to clean up symlinks (don't manually delete)
- SHOULD verify with `./dotfiles.sh status` after reinstall

## Advanced Package Patterns

### Conditional package installation
```bash
# In packages.config, comment out packages to skip:
git
ssh
# tmux      # Commented out - won't be installed
nvim:$XDG_CONFIG_DIR/nvim
```

### Testing new packages without committing
```bash
# Add to packages.config locally (don't commit yet)
echo "testpackage" >> packages.config

# Test installation
./dotfiles.sh status     # Check what would happen
./dotfiles.sh reinstall  # Actually install

# If it works, commit. If not, remove from packages.config
git checkout packages.config  # Revert if broken
```

### Handling Stow conflicts
```bash
# If Stow reports conflicts during status/reinstall:
# ERROR: Target ~/.myconfig already exists and is not a symlink

# Resolution options:
1. Back up existing file:   mv ~/.myconfig ~/.myconfig.backup
2. Remove existing file:     rm ~/.myconfig
3. Don't install package:    Remove from packages.config

# Then rerun:
./dotfiles.sh reinstall
```

### Multi-target packages
```bash
# Some packages may install to multiple locations
# Use directory structure to control:

mypackage/
├── .myconfig                    # Goes to ~/ (if target is ~/)
└── .config/
    └── mypackage/               # Goes to ~/.config/mypackage/
        └── settings.yml

# In packages.config (target is ~/):
mypackage

# Result:
# ~/.myconfig → symlink to repo/mypackage/.myconfig
# ~/.config/mypackage/ → symlink to repo/mypackage/.config/mypackage/
```

## Package Implementation Checklist

When adding a new package, verify:
- [ ] Package directory created with proper structure
- [ ] Configuration files placed in correct locations
- [ ] Directory structure mirrors target filesystem layout
- [ ] Added to packages.config with appropriate target
- [ ] Tested with `./dotfiles.sh status` (shows what would install)
- [ ] Tested with `./dotfiles.sh reinstall` (actually installs)
- [ ] Verified symlinks created in correct locations
- [ ] No conflicts with existing files
- [ ] Component documented in AGENTS.md if complex
- [ ] README.md updated if user-facing feature

## Cross-References

- docs/development/adding-features.md (Feature integration)
- docs/reference/dotfiles-commands.md (status/reinstall commands)
- CLAUDE.md (Quick reference)
