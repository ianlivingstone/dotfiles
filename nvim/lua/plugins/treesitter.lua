-- Treesitter configuration for the nvim-treesitter `main` branch.
--
-- NOTE: `main` is a full, incompatible rewrite of the old `master`-branch plugin:
--   * It does NOT support lazy-loading, so the spec uses `lazy = false`.
--   * Parsers are installed via require("nvim-treesitter").install{...}
--     instead of an `ensure_installed` table.
--   * Highlighting and indentation are NOT automatic — Neovim provides
--     highlighting (vim.treesitter.start) and the plugin provides an
--     (experimental) indent expression; both are enabled per-buffer below.
--
-- Requires the tree-sitter CLI (`brew install tree-sitter`) and a C compiler.
local M = {}

local lazy_available = pcall(require, "lazy")
if not lazy_available then
  return M
end

-- Parsers to install. markdown needs markdown_inline for fenced-code highlighting.
local ensure_parsers = {
  "typescript",
  "javascript",
  "go",
  "lua",
  "json",
  "html",
  "css",
  "markdown",
  "markdown_inline",
  "typespec",
}

M.plugins = {
  {
    "nvim-treesitter/nvim-treesitter",
    -- `main` branch, pinned to an exact commit so :Lazy update cannot move it.
    -- After bumping this commit you must run :TSUpdate to update installed parsers.
    branch = "main",
    commit = "4916d6592ede8c07973490d9322f187e07dfefac",
    build = ":TSUpdate",
    lazy = false, -- the main branch does not support lazy-loading
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter")
      if not ok then
        vim.notify("Failed to load nvim-treesitter", vim.log.levels.ERROR)
        return
      end

      ts.setup()

      -- Install/keep the parsers we need (async; a no-op if already installed).
      pcall(ts.install, ensure_parsers)

      -- Enable treesitter highlighting + indentation per buffer. On the main
      -- branch these are opt-in. We resolve the parser language from the
      -- filetype and only start when a parser is actually available, so files
      -- without an installed parser fall back to default behaviour cleanly.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("dotfiles_treesitter", { clear = true }),
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if ft == "" then
            return
          end
          local lang = vim.treesitter.language.get_lang(ft) or ft
          if pcall(vim.treesitter.start, args.buf, lang) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}

return M
