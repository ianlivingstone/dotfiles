# Tmux Configuration Architecture

**📋 Agent Rules Compliance**: This file follows Agent Rules specification using imperative statements with RFC 2119 keywords and flat bullet list format.

## Overview
The tmux package provides a modern terminal multiplexer configuration optimized for development workflows, with intuitive key bindings and visual enhancements.

## Design Principles
- MUST use Vi-style key bindings for familiar movement
- MUST provide modern status line with useful information for visual clarity
- MAY include optional mouse integration for convenience
- MUST optimize for coding and terminal workflows (development focused)
- MUST ensure efficient rendering and memory usage

## Configuration Architecture

### File Structure
```
tmux/
└── .tmux.conf             # Main tmux configuration (symlinked to ~/.tmux.conf)
```

### Core Configuration Sections

**Prefix Key and Basic Settings:**
```bash
# Change prefix from C-b to C-a (easier to reach)
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Basic settings
set -g default-terminal "screen-256color"  # 256 color support
set -g mouse on                            # Enable mouse support
set -g history-limit 10000                 # Increase scrollback buffer
set -sg escape-time 1                      # Faster command sequences
```

## Key Binding Architecture

### Window Management
```bash
# Window creation and navigation
bind c new-window                          # Create new window
bind n next-window                         # Next window
bind p previous-window                     # Previous window
bind , command-prompt "rename-window '%%'" # Rename window

# Window splitting (more intuitive)
bind | split-window -h                     # Horizontal split
bind - split-window -v                     # Vertical split
```

### Pane Management
```bash
# Pane navigation (Vi-style)
bind h select-pane -L                      # Move left
bind j select-pane -D                      # Move down  
bind k select-pane -U                      # Move up
bind l select-pane -R                      # Move right

# Pane resizing
bind -r H resize-pane -L 5                 # Resize left
bind -r J resize-pane -D 5                 # Resize down
bind -r K resize-pane -U 5                 # Resize up
bind -r L resize-pane -R 5                 # Resize right
```

### Copy Mode (Vi-style)
```bash
# Enter copy mode
bind Escape copy-mode

# Vi-style copy mode bindings
setw -g mode-keys vi
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel

# System clipboard integration (macOS)
bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "pbcopy"
```

## Visual Design

### Status Line Configuration
```bash
# Status line positioning and refresh
set -g status-position bottom
set -g status-interval 5                   # Update every 5 seconds

# Status line colors and styling
set -g status-bg colour234                 # Dark grey background
set -g status-fg colour137                 # Light text
set -g status-left-length 20
set -g status-right-length 50

# Left status: session name
set -g status-left '#[fg=colour233,bg=colour241,bold] #S #[fg=colour241,bg=colour234,nobold]'

# Right status: hostname, date, time
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
```

### Window Status Styling
```bash
# Default window status
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

# Active window status
setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '

# Window status colors
setw -g window-status-current-bg colour238
setw -g window-status-current-fg colour81
setw -g window-status-current-attr bold
```

### Pane Styling
```bash
# Pane border colors
set -g pane-border-fg colour238
set -g pane-active-border-fg colour51

# Pane numbering
set -g display-panes-time 2000             # Display pane numbers longer
set -g display-panes-colour colour166
set -g display-panes-active-colour colour33
```

## Development Workflow Integration

### Session Management
```bash
# Quick session commands
bind s choose-session                       # Session selector
bind S command-prompt "new-session -s '%%'" # Create named session
bind R source-file ~/.tmux.conf \; display "Reloaded!" # Reload config
```

### Development-Focused Features
```bash
# Automatic window renaming based on current command
setw -g automatic-rename on
set -g set-titles on
set -g set-titles-string "#T"

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity on

# Start windows and panes at 1 (easier keyboard access)
set -g base-index 1
setw -g pane-base-index 1
```

## Performance Optimization

### Rendering and Display
```bash
# Reduce unnecessary updates
set -g status-interval 5                   # Status updates every 5 seconds
set -sg escape-time 1                      # Faster escape sequence processing
set -g repeat-time 600                     # Repeat threshold for key bindings

# Efficient history management
set -g history-limit 10000                 # Reasonable scrollback limit
```

### Memory Management
```bash
# Automatic cleanup
set -g destroy-unattached on               # Kill sessions when no clients attached
setw -g aggressive-resize on               # Resize windows aggressively
```

## Integration with Development Tools

### Terminal Integration
```bash
# Proper terminal type
set -g default-terminal "screen-256color"  # 256 color support
set -ga terminal-overrides ",*256col*:Tc"  # True color support

# Shell integration
set -g default-shell /bin/zsh              # Use zsh as default shell
```

### Editor Integration
**Neovim/Vim compatibility:**
```bash
# Ensure proper escape sequence handling
set -sg escape-time 1

# Enable focus events for Neovim
set -g focus-events on

# Proper clipboard handling
set -g set-clipboard on
```

## Multi-Platform Considerations

### macOS Specific Settings
```bash
# macOS clipboard integration
if-shell "uname | grep -q Darwin" \
    'bind-key -T copy-mode-vi "y" send -X copy-pipe-and-cancel "pbcopy"'

# macOS terminal title setting
if-shell "uname | grep -q Darwin" \
    'set -g set-titles-string "#h:#S:#W"'
```

### Linux Specific Settings
```bash
# Linux clipboard integration (requires xclip)
if-shell "uname | grep -q Linux" \
    'bind-key -T copy-mode-vi "y" send -X copy-pipe-and-cancel "xclip -selection clipboard"'
```

## Common Workflows

### Development Session Setup
**Typical development session structure:**
```bash
# Session: project-name
# Window 0: editor (nvim)
# Window 1: server (npm run dev, rails server, etc.)
# Window 2: tests (npm test, pytest, etc.)
# Window 3: git/terminal
```

**Quick setup commands:**
```bash
# Create development session
tmux new-session -d -s project-name
tmux send-keys -t project-name:0 'nvim' Enter
tmux new-window -t project-name -n server
tmux new-window -t project-name -n tests  
tmux new-window -t project-name -n git
tmux select-window -t project-name:0
tmux attach-session -t project-name
```

## Configuration Management

### Reload and Testing
```bash
# Reload configuration
bind R source-file ~/.tmux.conf \; display "Reloaded!"

# Test configuration
tmux source-file ~/.tmux.conf    # Command line reload
```

### Customization Guidelines
**Adding new key bindings:**
```bash
# Follow existing patterns
bind key-combination action      # Basic binding
bind -r key-combination action   # Repeatable binding
bind -n key-combination action   # No prefix required
```

**Color scheme modifications:**
```bash
# Use consistent color numbers
# Standard colors: 0-15 (system colors)
# Extended colors: 16-255 (256 color mode)
# Use colour names or numbers consistently
```

## Integration with Dotfiles System

### Stow Integration
- **Symlink management**: GNU Stow handles tmux config linking
- **Target directory**: Default target (`~/`)
- **Package validation**: Status checking ensures proper linking

### Version Requirements
- **Tmux version**: Minimum version defined in `versions.config`
- **Feature compatibility**: Configuration uses modern tmux features
- **Cross-version compatibility**: Graceful degradation for older versions

### Status Integration
**Status reporting includes tmux:**
```bash
if command -v tmux &>/dev/null; then
    echo "✅ Tmux: $(tmux -V | awk '{print $2}')"
else
    echo "❌ Tmux: Not installed"
fi
```

## Security Considerations

### Session Security
```bash
# Secure session handling
set -g lock-after-time 1800              # Auto-lock after 30 minutes
set -g lock-command "vlock"               # Lock command (if available)
```

### Network Considerations
- **No network features**: Tmux operates locally only
- **Socket permissions**: Tmux sockets secured to user access only
- **Session isolation**: Each user's sessions are isolated

## Troubleshooting

### Common Issues

**Color Problems:**
```bash
# Check terminal capability
echo $TERM                               # Should be screen-256color in tmux
tput colors                              # Should report 256

# Test colors
tmux show -g default-terminal           # Check tmux terminal setting
```

**Key Binding Issues:**
```bash
# List current key bindings
tmux list-keys                          # Show all bindings
tmux list-keys -T copy-mode-vi          # Show copy mode bindings

# Test specific binding
tmux send-keys 'test binding'           # Test key sending
```

**Performance Issues:**
```bash
# Check session information
tmux info                               # Show tmux server info
tmux list-sessions                      # Show active sessions
tmux list-windows                       # Show session windows

# Monitor resource usage
tmux show -g status-interval            # Check update frequency
```

### Configuration Validation
```bash
# Test configuration syntax
tmux source-file ~/.tmux.conf           # Load config file
tmux show -g                            # Show global options
tmux show -w                            # Show window options
```

## Development Guidelines

### Adding New Features
**1. Test compatibility:**
```bash
# Check tmux version requirements
tmux -V                                 # Check current version
man tmux                                # Check feature availability
```

**2. Follow existing patterns:**
- Use consistent key binding conventions
- Follow color scheme patterns
- Maintain performance considerations

**3. Document changes:**
- Update this agent.md file
- Add comments for complex configurations
- Test across different tmux versions

This architecture provides a robust, efficient terminal multiplexer configuration that enhances development productivity while maintaining simplicity and performance.