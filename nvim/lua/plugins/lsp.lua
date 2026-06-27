-- LSP configuration (Neovim 0.11+ API: vim.lsp.config / vim.lsp.enable)
--
-- We no longer use the deprecated `require('lspconfig')` framework. nvim-lspconfig
-- still ships the per-server defaults (cmd/filetypes/root) under lsp/<name>.lua on the
-- runtimepath; vim.lsp.config() merges our overrides with those, and vim.lsp.enable()
-- turns the servers on. mason installs the server binaries.
local M = {}

local lazy_available = pcall(require, "lazy")
if not lazy_available then
  return M
end

M.plugins = {
  {
    "neovim/nvim-lspconfig",
    ft = { "typescript", "javascript", "go", "lua", "json", "typespec" }, -- load for these filetypes
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Mason installs server binaries; we enable servers explicitly below.
      local mason_ok, mason = pcall(require, "mason")
      if mason_ok then
        mason.setup()
      end

      local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
      if mason_lspconfig_ok then
        mason_lspconfig.setup({
          ensure_installed = { "ts_ls", "biome", "lua_ls" }, -- gopls comes from gvm
          automatic_enable = false, -- we call vim.lsp.enable() ourselves
        })
      end

      -- Diagnostics. (source = true; the "always"/"if_many" strings are deprecated.)
      vim.diagnostic.config({
        virtual_text = { prefix = "●", source = true },
        float = { source = true, border = "rounded" },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Shared capabilities for every server (nvim-cmp integration), applied via
      -- the "*" pseudo-config so each server inherits it.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if cmp_nvim_lsp_ok then
        capabilities = cmp_nvim_lsp.default_capabilities()
      end
      vim.lsp.config("*", { capabilities = capabilities })

      -- TypeScript / JavaScript
      local ts_inlay_hints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      }
      vim.lsp.config("ts_ls", {
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
        init_options = {
          preferences = {
            includeCompletionsForModuleExports = true,
            includeCompletionsForImportStatements = true,
          },
        },
        settings = {
          typescript = {
            inlayHints = ts_inlay_hints,
            suggest = { autoImports = true },
            preferences = { includePackageJsonAutoImports = "auto" },
          },
          javascript = {
            inlayHints = ts_inlay_hints,
            suggest = { autoImports = true },
            preferences = { includePackageJsonAutoImports = "auto" },
          },
        },
      })

      -- Biome (formatter/linter LSP)
      vim.lsp.config("biome", {
        root_markers = { "biome.json", "biome.jsonc", ".git" },
        single_file_support = false,
        on_attach = function(client, _)
          client.server_capabilities.documentFormattingProvider = true
          client.server_capabilities.documentRangeFormattingProvider = true
        end,
      })

      -- Go (gopls from gvm/PATH)
      vim.lsp.config("gopls", {
        cmd = { "gopls" },
        root_markers = { "go.mod", ".git" },
        settings = {
          gopls = {
            gofumpt = true,
            codelenses = {
              gc_details = false,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
            analyses = {
              nilness = true,
              unusedparams = true,
              unusedwrite = true,
              useany = true,
            },
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
            directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
            semanticTokens = true,
            ["local"] = "",
          },
        },
      })

      -- Lua
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
          },
        },
      })

      -- TypeSpec
      vim.lsp.config("typespec_ls", {
        cmd = { "tsp-server", "--stdio" },
        filetypes = { "typespec" },
        root_markers = { "tspconfig.yaml", "package.json", ".git" },
      })

      vim.lsp.enable({ "ts_ls", "biome", "gopls", "lua_ls", "typespec_ls" })

      -- LSP keymaps (set per buffer on attach)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
          vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
          vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Go to references" }))
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, vim.tbl_extend("force", opts, { desc = "Format" }))

          -- Diagnostic keymaps (jump() replaces the deprecated goto_prev/goto_next)
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Open diagnostic float" }))
          vim.keymap.set("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
          vim.keymap.set("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
          vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Diagnostic loclist" }))

          -- Go-specific: organize imports
          if vim.bo.filetype == "go" then
            vim.keymap.set("n", "<leader>gi", function()
              vim.lsp.buf.code_action({
                context = { only = { "source.organizeImports" } },
                apply = true,
              })
            end, vim.tbl_extend("force", opts, { desc = "Go organize imports" }))
          end
        end,
      })
    end,
  },
}

return M
