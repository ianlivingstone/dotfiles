-- Editor enhancement plugins
local M = {}

local lazy_available = pcall(require, "lazy")
if not lazy_available then
  return M
end

M.plugins = {
  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
    },
    config = function()
      local ok, nvim_tree = pcall(require, "nvim-tree")
      if not ok then
        vim.notify("Failed to load nvim-tree", vim.log.levels.ERROR)
        return
      end
      
      nvim_tree.setup({
        git = {
          enable = true,
        },
        view = {
          width = 30,
        },
      })
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter", -- Lazy load on entering insert mode
    config = function()
      local ok, autopairs = pcall(require, "nvim-autopairs")
      if not ok then
        vim.notify("Failed to load nvim-autopairs", vim.log.levels.ERROR)
        return
      end
      
      autopairs.setup()
    end,
  },
}

return M