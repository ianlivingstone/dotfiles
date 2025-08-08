-- Colorscheme configuration
local M = {}

local lazy_available = pcall(require, "lazy")
if not lazy_available then
  -- Fallback to built-in colorscheme
  vim.cmd("colorscheme default")
  return M
end

M.plugins = {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- Load first
    config = function()
      local ok, catppuccin = pcall(require, "catppuccin")
      if ok then
        vim.cmd("colorscheme catppuccin-mocha")
      else
        vim.notify("Failed to load catppuccin, using default colorscheme", vim.log.levels.WARN)
        vim.cmd("colorscheme default")
      end
    end,
  },
}

return M