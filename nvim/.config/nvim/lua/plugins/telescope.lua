-- Telescope fuzzy finder configuration
local M = {}

local lazy_available = pcall(require, "lazy")
if not lazy_available then
  return M
end

M.plugins = {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope", -- Lazy load on command
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    },
    config = function()
      local ok, telescope = pcall(require, "telescope")
      if not ok then
        vim.notify("Failed to load telescope", vim.log.levels.ERROR)
        return
      end
      
      telescope.setup({
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "truncate" },
        },
      })
    end,
  },
}

return M