# dotfiles.sh Command Reference

## Command Overview

The `dotfiles.sh` script is the main management interface for the dotfiles system.

**Available commands:**
- `install` - Initial installation with interactive configuration
- `status` - Validate installation and check version compliance
- `update` - Update Node.js and Go to versions specified in versions.config
- `reinstall` - Uninstall and reinstall all packages
- `uninstall` - Remove all dotfiles symlinks
- `help` - Show help information

## install Command

**Purpose:** Perform initial installation with interactive machine-specific configuration.

**Implementation location:** `dotfiles.sh` main script

**Workflow:**
1. `check_dependencies()` - Validates all required tools are installed
2. `prompt_git_user()` - Interactive Git identity setup (name, email)
3. `scan_ssh_keys()` - Detects available SSH keys and prompts for selection
4. `scan_gpg_keys()` - Detects available GPG keys and prompts for selection
5. `generate_machine_configs()` - Creates machine.config files in XDG directories
6. `install_packages()` - Runs GNU Stow to install all packages from packages.config
7. `validate_installation()` - Confirms successful setup

**Usage:**
```bash
./dotfiles.sh install
```

**MUST understand install behavior:**
- Interactive prompts use `/dev/tty` for stdin compatibility
- Checks for existing machine.config files and offers to reuse or overwrite
- Validates all dependencies before proceeding
- Creates XDG directory structure if missing
- Sets proper permissions on generated configs
- Idempotent - safe to run multiple times

**SHOULD re-run to reconfigure machine-specific settings:**
```bash
# Reconfigure Git identity
./dotfiles.sh install

# Or manually edit machine configs:
vim ~/.config/git/machine.config
vim ~/.config/ssh/machine.config
```

## status Command

**Purpose:** Validate installation status and check version compliance.

**Implementation location:** `dotfiles.sh` main script

**What it checks:**
1. **Version compliance** - Validates tools against versions.config requirements
2. **Package installation** - Uses GNU Stow's `--no --restow` to check each package
3. **Claude hooks** - Checks if hooks are built and up-to-date

**Usage:**
```bash
./dotfiles.sh status
```

**Output format:**
```
=== Dotfiles Status ===

Version Compliance:
✅ git 2.45.0 (required: 2.40+)
✅ docker 28.1.0 (required: 28.0+)
❌ nvim 0.8.3 (required: 0.9+)  # Needs update

Package Status:
✅ git → properly stowed to /Users/ian
✅ ssh → properly stowed to /Users/ian
❌ nvim → would make changes:
    LINK: init.lua
    LINK: lazy-lock.json
⚠️  missing → package directory not found

Claude Hooks:
✅ hooks built and current
```

**MUST understand status validation:**
- Uses Stow's own logic for authoritative validation
- Shows exactly what `reinstall` would do
- Version checks use proper semantic versioning comparison
- Exit code 0 if all checks pass, non-zero if issues found

**Testing status command:**
```bash
# Should show all packages properly stowed
./dotfiles.sh status

# Verify version checking works
# (Temporarily modify versions.config to test)
```

## update Command

**Purpose:** Update Node.js and Go to versions specified in versions.config.

**Implementation location:** `dotfiles.sh` main script

**What it updates:**
- **Node.js** - Uses NVM to install specified version
- **Go** - Uses GVM to install specified version
- ~~Other tools~~ - Not yet implemented (manual installation required)

**Usage:**
```bash
./dotfiles.sh update
```

**Workflow:**
1. Read versions from versions.config
2. Check if NVM/GVM are installed
3. Install version managers if missing (prompts user)
4. Use version managers to install specified versions
5. Validate successful installation
6. Set newly installed versions as default

**MUST understand update behavior:**
- Only updates Node.js and Go (other tools manual)
- Requires NVM for Node.js updates
- Requires GVM for Go updates
- Does not downgrade versions (only installs if newer or missing)
- Validates version managers are installed first

**Example update session:**
```bash
$ ./dotfiles.sh update
Reading versions from versions.config...
  Node.js target: v24.1.0
  Go target: go1.24.1

Checking NVM installation...
✅ NVM found

Installing Node.js v24.1.0...
✅ Node.js v24.1.0 installed successfully

Checking GVM installation...
✅ GVM found

Installing Go go1.24.1...
✅ Go go1.24.1 installed successfully

Update complete!
```

## reinstall Command

**Purpose:** Uninstall and reinstall all packages (safe way to test changes).

**Implementation location:** `dotfiles.sh` main script

**Workflow:**
1. Read packages.config to determine active packages
2. Unstow all packages currently installed
3. Stow all packages listed in packages.config

**Usage:**
```bash
./dotfiles.sh reinstall
```

**MUST understand reinstall behavior:**
- Removes symlinks for packages NOT in packages.config
- Creates symlinks for packages IN packages.config
- Safe way to test package changes
- Does not regenerate machine.config files (reuses existing)
- Uses same Stow logic as initial installation

**Common use cases:**
```bash
# After adding a new package to packages.config
echo "mypackage" >> packages.config
./dotfiles.sh reinstall

# After removing a package from packages.config
sed -i '' '/^oldpackage/d' packages.config
./dotfiles.sh reinstall

# After modifying a package's files
# (Edit files in packagename/ directory)
./dotfiles.sh reinstall
```

## uninstall Command

**Purpose:** Remove all dotfiles symlinks (cleanup).

**Implementation location:** `dotfiles.sh` main script

**Workflow:**
1. Read packages.config
2. Unstow each package using GNU Stow
3. Remove symlinks but preserve machine.config files

**Usage:**
```bash
./dotfiles.sh uninstall
```

**MUST understand uninstall behavior:**
- Removes symlinks created by Stow
- Does NOT delete package directories from repository
- Does NOT delete machine.config files in ~/.config/
- Does NOT uninstall tools (Git, Neovim, etc. remain)
- Reversible with `./dotfiles.sh install`

**Example uninstall session:**
```bash
$ ./dotfiles.sh uninstall
Uninstalling dotfiles...
✅ Unstowed: git
✅ Unstowed: ssh
✅ Unstowed: tmux
✅ Unstowed: nvim
✅ Unstowed: starship

Uninstall complete!
Machine-specific configs preserved in ~/.config/
```

## help Command

**Purpose:** Show help information and available commands.

**Usage:**
```bash
./dotfiles.sh help
# Or:
./dotfiles.sh --help
# Or:
./dotfiles.sh
```

## Implementation Details

### Command-line parsing
```bash
# dotfiles.sh uses simple case statement
case "${1:-}" in
    install)
        install_dotfiles
        ;;
    status)
        check_status
        ;;
    update)
        update_versions
        ;;
    reinstall)
        reinstall_packages
        ;;
    uninstall)
        uninstall_packages
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
```

### Error handling
- MUST exit with non-zero code on errors
- MUST provide clear error messages
- MUST suggest remediation steps
- SHOULD validate preconditions before operations

### Dependency checking pattern
```bash
check_dependencies() {
    local missing=()

    for tool in git stow nvim tmux; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing dependencies: ${missing[*]}"
        echo "Install with: brew install ${missing[*]}"
        return 1
    fi

    return 0
}
```

## Cross-References

- docs/development/adding-features.md (Integration requirements)
- docs/development/package-management.md (How commands use Stow)
- docs/security/multi-machine.md (install command machine config)
