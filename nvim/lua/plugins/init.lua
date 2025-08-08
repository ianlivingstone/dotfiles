-- Main plugin loader
-- Check if lazy is available after bootstrap
local lazy_available, lazy = pcall(require, "lazy")
if not lazy_available then
  vim.notify("Failed to load lazy.nvim, plugins disabled", vim.log.levels.ERROR)
  return
end

-- Collect all plugin specs
local plugins = {}

-- Safely load each plugin module
local plugin_modules = {
  "plugins.colorscheme",
  "plugins.completion",
  "plugins.lsp",
  "plugins.telescope",
  "plugins.treesitter",
  "plugins.editor",
  "plugins.ui",
  "plugins.coding",
}

for _, module_name in ipairs(plugin_modules) do
  local ok, module = pcall(require, module_name)
  if ok and module.plugins then
    vim.list_extend(plugins, module.plugins)
  else
    vim.notify("Failed to load " .. module_name, vim.log.levels.WARN)
  end
end

-- Setup lazy with all collected plugins
lazy.setup(plugins, {
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  install = {
    missing = true,
  },
  change_detection = {
    enabled = true, -- Detect config changes but don't auto-update
    notify = true,  -- Notify about changes and suggest manual update
  },
  rocks = {
    enabled = true,
    root = vim.fn.stdpath("data") .. "/lazy-rocks",
    server = "https://nvim-neorocks.github.io/rocks-binaries/",
  },
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true,
    rtp = {
      reset = true,
      paths = {},
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})