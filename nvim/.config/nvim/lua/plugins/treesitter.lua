-- Treesitter syntax highlighting configuration
local M = {}

local lazy_available = pcall(require, "lazy")
if not lazy_available then
  return M
end

M.plugins = {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" }, -- Lazy load on file open
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        vim.notify("Failed to load nvim-treesitter", vim.log.levels.ERROR)
        return
      end
      
      configs.setup({
        ensure_installed = {
          "typescript",
          "javascript",
          "go",
          "lua",
          "json",
          "html",
          "css",
          "markdown",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}

return M