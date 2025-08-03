-- LSP configuration
local M = {}

local lazy_available = pcall(require, "lazy")
if not lazy_available then
  return M
end

M.plugins = {
  {
    "neovim/nvim-lspconfig",
    ft = { "typescript", "javascript", "go", "lua", "json" }, -- Load only for these filetypes
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Check if all required modules are available
      local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
      local mason_ok, mason = pcall(require, "mason")
      local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
      local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      
      if not lspconfig_ok then
        vim.notify("Failed to load lspconfig", vim.log.levels.ERROR)
        return
      end
      
      if not mason_ok then
        vim.notify("Failed to load mason", vim.log.levels.ERROR)
        return
      end
      
      if not mason_lspconfig_ok then
        vim.notify("Failed to load mason-lspconfig", vim.log.levels.ERROR)
        return
      end
      
      -- Mason setup
      mason.setup()
      mason_lspconfig.setup({
        ensure_installed = {
          "ts_ls",
          "biome",
          "lua_ls",
          -- Don't auto-install gopls since you have it via gvm
        },
        automatic_installation = false,
      })

      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = {
          prefix = "●",
          source = "always",
        },
        float = {
          source = "always",
          border = "rounded",
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Get capabilities from cmp if available
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      if cmp_nvim_lsp_ok then
        capabilities = cmp_nvim_lsp.default_capabilities()
      end

      -- TypeScript/JavaScript
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
        root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
        init_options = {
          preferences = {
            includeCompletionsForModuleExports = true,
            includeCompletionsForImportStatements = true,
          },
        },
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
            suggest = {
              autoImports = true,
            },
            preferences = {
              includePackageJsonAutoImports = "auto",
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
            suggest = {
              autoImports = true,
            },
            preferences = {
              includePackageJsonAutoImports = "auto",
            },
          },
        },
      })

      -- Biome
      lspconfig.biome.setup({
        capabilities = capabilities,
        root_dir = lspconfig.util.root_pattern("biome.json", "biome.jsonc", ".git"),
        single_file_support = false,
        on_attach = function(client, bufnr)
          -- Enable formatting capability
          client.server_capabilities.documentFormattingProvider = true
          client.server_capabilities.documentRangeFormattingProvider = true
        end,
      })

      -- Go
      lspconfig.gopls.setup({
        capabilities = capabilities,
        cmd = { "gopls" }, -- Use system gopls from PATH
        root_dir = lspconfig.util.root_pattern("go.mod", ".git"),
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
            -- Enhanced import handling
            ["local"] = "",
            gofumpt = true,
            ["ui.completion.usePlaceholders"] = true,
            ["ui.diagnostic.analyses"] = {
              unusedparams = true,
              unusedwrite = true,
            },
          },
        },
      })

      -- Lua
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
            telemetry = { enable = false },
          },
        },
      })

      -- LSP keymaps
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
          
          -- Diagnostic keymaps
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Open diagnostic float" }))
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
          vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Diagnostic loclist" }))
          
          -- Go-specific keymaps
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