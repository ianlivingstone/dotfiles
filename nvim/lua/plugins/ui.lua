-- UI enhancement plugins
local M = {}

local lazy_available = pcall(require, "lazy")
if not lazy_available then
  return M
end

M.plugins = {
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy", -- Load after startup
    config = function()
      local ok, lualine = pcall(require, "lualine")
      if not ok then
        vim.notify("Failed to load lualine", vim.log.levels.ERROR)
        return
      end
      
      lualine.setup({
        options = {
          theme = "catppuccin",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- Load when opening files
    config = function()
      local ok, gitsigns = pcall(require, "gitsigns")
      if not ok then
        vim.notify("Failed to load gitsigns", vim.log.levels.ERROR)
        return
      end
      
      gitsigns.setup({
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
      })
    end,
  },

  -- Web dev icons (dependency for other plugins)
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true, -- Only load when required by other plugins
  },
}

return M