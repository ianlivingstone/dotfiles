# Neovim Configuration Architecture

**📋 Agent Rules Compliance**: This file follows Agent Rules specification using imperative statements with RFC 2119 keywords and flat bullet list format.

## Overview
The Neovim package follows a sophisticated modular design with lazy loading, graceful degradation, and minimal startup overhead.

## Design Principles
- MUST use minimal entry point: `init.lua` only bootstraps and loads modules
- MUST load plugins only when needed (lazy loading)
- MUST ensure missing dependencies don't break core functionality (graceful degradation)
- MUST maintain clear separation between config and plugins
- MUST load core functionality first, optional features later for fast startup

## Directory Structure

```
nvim/.config/nvim/
├── init.lua                    # Minimal entry point (12 lines)
└── lua/
    ├── config/
    │   ├── options.lua        # Vim settings (no dependencies)
    │   ├── keymaps.lua        # Global keymaps (no dependencies)
    │   ├── autocmds.lua       # File-specific autocommands
    │   └── lazy-bootstrap.lua # Plugin manager installation
    └── plugins/
        ├── init.lua           # Main plugin loader & orchestrator
        ├── colorscheme.lua    # Theme configuration
        ├── completion.lua     # Autocompletion system
        ├── lsp.lua           # Language Server Protocol
        ├── telescope.lua     # Fuzzy finder
        ├── treesitter.lua    # Syntax highlighting
        ├── editor.lua        # File explorer & editor enhancements
        ├── ui.lua           # Status line & UI components
        └── coding.lua       # Coding utilities
```

## Loading Sequence

### 1. Bootstrap Phase (`init.lua`)
```lua
-- Set leader key first (required by some plugins)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Load core configuration (no plugin dependencies)
require("config.options")
require("config.keymaps") 
require("config.autocmds")

-- Bootstrap lazy.nvim plugin manager
require("config.lazy-bootstrap")

-- Load all plugins via lazy.nvim
require("plugins")
```

### 2. Core Configuration Phase
**No plugin dependencies - always loads:**
- **`options.lua`**: Vim settings, editor behavior
- **`keymaps.lua`**: Global key mappings
- **`autocmds.lua`**: File-type specific autocommands

### 3. Plugin Manager Bootstrap
**`lazy-bootstrap.lua`** automatically installs lazy.nvim if missing:
```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- Auto-install lazy.nvim
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", 
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)
```

### 4. Plugin Loading Phase
**Lazy loading with triggers:**
- **`ft`**: Load on specific file types
- **`cmd`**: Load when command is executed  
- **`keys`**: Load when key mapping is used
- **`event`**: Load on Vim events

## Plugin Architecture

### Plugin Categorization
Each plugin file handles a specific domain:

**Core Editor (`editor.lua`):**
- File explorer (nvim-tree)
- Buffer management
- Window navigation
- Search and replace

**Language Support (`lsp.lua`, `completion.lua`):**
- Language Server Protocol integration
- Autocompletion engine
- Diagnostics and formatting
- Code actions

**Developer Experience (`telescope.lua`, `coding.lua`):**
- Fuzzy finding
- Git integration
- Debugging tools
- Code snippets

**UI/UX (`ui.lua`, `colorscheme.lua`):**
- Status line
- Color schemes
- Visual enhancements
- Notifications

### Plugin Configuration Pattern
Each plugin file follows this structure:

```lua
return {
  -- Plugin specification
  "author/plugin-name",
  
  -- Lazy loading configuration
  ft = { "lua", "javascript" },  -- or cmd, keys, event
  
  -- Dependencies
  dependencies = {
    "required/dependency"
  },
  
  -- Plugin configuration
  config = function()
    local plugin = require("plugin-name")
    plugin.setup({
      -- Configuration options
      option1 = "value1",
      option2 = {
        nested = "value"
      }
    })
    
    -- Custom keymaps for this plugin
    vim.keymap.set("n", "<leader>p", plugin.action, { desc = "Plugin action" })
  end,
  
  -- Build step if needed
  build = "make install"
}
```

## Error Handling Strategy

### Graceful Plugin Loading
```lua
-- Safe plugin loading with error handling
local ok, plugin = pcall(require, "plugin-name")
if not ok then
  vim.notify("Plugin 'plugin-name' not available", vim.log.levels.WARN)
  return
end

-- Safe plugin setup
local setup_ok, _ = pcall(plugin.setup, config)
if not setup_ok then
  vim.notify("Failed to setup plugin-name", vim.log.levels.ERROR)
end
```

### Dependency Checks
```lua
-- Check if external dependency exists
if vim.fn.executable("language-server") == 0 then
  vim.notify("language-server not found", vim.log.levels.WARN)
  return {}  -- Return empty plugin spec
end
```

## Performance Optimization

### Startup Time Targets
- **Core config loading**: <10ms
- **Plugin manager bootstrap**: <50ms  
- **Essential plugins**: <100ms
- **All plugins (lazy loaded)**: <200ms total

### Lazy Loading Strategies

**File Type Triggers:**
```lua
ft = { "python", "lua", "javascript" }  -- Load only for specific languages
```

**Command Triggers:**
```lua
cmd = { "Telescope", "TelescopeFind" }  -- Load when command is run
```

**Key Mapping Triggers:**
```lua
keys = {
  { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" }
}
```

**Event Triggers:**
```lua
event = { "BufReadPre", "BufNewFile" }  -- Load on buffer events
```

## Plugin Management

### Version Control
- **`lazy-lock.json`**: Locks plugin versions for consistency
- **Committed to git**: Ensures same plugin versions across machines
- **Manual updates**: Use `:Lazy sync` to update plugins and lockfile

### Plugin Updates
```vim
:Lazy                      " Open plugin manager UI
:Lazy sync                 " Update plugins and lockfile (recommended)
:Lazy update               " Update plugins only
:Lazy clean                " Remove unused plugins
```

## Language Server Protocol (LSP)

### Architecture
**Mason integration** for automatic LSP server management:
```lua
-- Automatic LSP server installation
local servers = {
  "lua_ls",           -- Lua
  "pyright",          -- Python  
  "tsserver",         -- TypeScript/JavaScript
  "gopls",            -- Go
  "rust_analyzer",    -- Rust
}

-- Auto-install missing servers
for _, server in ipairs(servers) do
  if not mason_registry.is_installed(server) then
    mason_registry.get_package(server):install()
  end
end
```

### LSP Configuration Pattern
```lua
-- Consistent LSP setup across all servers
local function setup_lsp(server_name, custom_config)
  local default_config = {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
    on_attach = function(client, bufnr)
      -- Standard LSP keymaps
      local opts = { buffer = bufnr }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      -- ... more keymaps
    end
  }
  
  local config = vim.tbl_deep_extend("force", default_config, custom_config or {})
  require("lspconfig")[server_name].setup(config)
end
```

## Development Guidelines

### Adding New Plugins

**1. Determine Category:**
- Does it fit in an existing plugin file?
- Does it need a new category file?

**2. Choose Loading Strategy:**
- What triggers should activate it?
- What dependencies does it have?

**3. Add Plugin Spec:**
```lua
-- In appropriate plugins/category.lua file
{
  "author/new-plugin",
  ft = { "relevant", "filetypes" },
  dependencies = { "required/dependency" },
  config = function()
    require("new-plugin").setup({
      -- Plugin configuration
    })
  end
}
```

**4. Test Loading:**
```vim
:Lazy reload new-plugin  " Reload plugin configuration
:Lazy profile           " Check startup performance impact
```

### Debugging Plugin Issues

**Check Plugin Status:**
```vim
:Lazy                   " View all plugins and their status
:checkhealth           " Run health checks for all plugins
:checkhealth plugin    " Check specific plugin health
```

**Performance Profiling:**
```vim
:Lazy profile          " View plugin loading times
```

**Log Inspection:**
```lua
-- View Neovim logs
vim.cmd("edit " .. vim.fn.stdpath("log") .. "/lsp.log")
```

## Integration with Dotfiles System

### Version Requirements
- Neovim version requirement defined in `versions.config`
- Status checking validates Neovim version compliance
- Plugin compatibility ensured through version constraints

### Fresh Installation Process
1. **Delete plugin cache**: `rm -rf ~/.local/share/nvim/`
2. **Start Neovim**: `nvim`
3. **Automatic bootstrap**: Lazy.nvim auto-installs and configures all plugins
4. **LSP servers**: Mason automatically installs configured language servers

### Configuration Backup/Restore
- **Plugin configurations**: Versioned in git repository
- **Plugin versions**: Locked in `lazy-lock.json`
- **LSP server binaries**: Managed by Mason (not versioned)
- **User data**: Stored in `~/.local/share/nvim/` (not versioned)

## Security Considerations

### Plugin Sources
- **Official repositories**: Prefer well-maintained, popular plugins
- **Version locking**: Use `lazy-lock.json` to prevent automatic updates
- **Review changes**: Check plugin updates before applying

### Network Security
- **HTTPS only**: All plugin URLs use HTTPS
- **Signature verification**: Lazy.nvim verifies git commits where possible
- **Sandboxed execution**: Plugins run in Neovim's sandboxed environment

This architecture provides a maintainable, performant, and extensible Neovim configuration that scales from basic editing to full IDE functionality while maintaining fast startup times and system stability.