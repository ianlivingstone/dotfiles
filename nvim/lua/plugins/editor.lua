-- Editor enhancement plugins
local M = {}

local lazy_available = pcall(require, "lazy")
if not lazy_available then
  return M
end

M.plugins = {
  -- Claude Code integration
  {
    "greggh/claude-code.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local ok, claude_code = pcall(require, "claude-code")
      if not ok then
        vim.notify("Failed to load claude-code", vim.log.levels.ERROR)
        return
      end
      claude_code.setup({
        -- Default configuration
        window = {
          split = "right",
          size = 80,
        },
      })
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
    },
    init = function()
      -- Auto-open nvim-tree when starting nvim with a directory
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
          -- Check if we opened a directory
          local directory = vim.fn.isdirectory(data.file) == 1
          
          if directory then
            -- Delete the directory buffer
            vim.cmd.bdelete(data.buf)
            
            -- Change to the directory
            vim.cmd.cd(data.file)
            
            -- Force load nvim-tree plugin before using it
            require("lazy").load({ plugins = { "nvim-tree.lua" } })
            
            -- Open nvim-tree
            require("nvim-tree.api").tree.open()
          end
        end,
      })
    end,
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