-- Global autocommands

-- TypeScript/JavaScript autocommands
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function(args)
    -- Check if Biome LSP is attached first (preferred)
    local biome_clients = vim.lsp.get_clients({ bufnr = args.buf, name = "biome" })
    if #biome_clients > 0 then
      -- Use Biome for formatting and organizing imports
      vim.lsp.buf.format({ bufnr = args.buf, async = false, timeout_ms = 3000, name = "biome" })
      return
    end

    -- Fallback to TypeScript LSP if Biome is not available
    local ts_clients = vim.lsp.get_clients({ bufnr = args.buf, name = "ts_ls" })
    if #ts_clients == 0 then
      return
    end

    -- Execute TypeScript organize imports command directly
    vim.lsp.buf.execute_command({
      command = "_typescript.organizeImports",
      arguments = {vim.uri_from_bufnr(args.buf)}
    })
    
    -- Format the buffer with TypeScript LSP
    vim.lsp.buf.format({ bufnr = args.buf, async = false, timeout_ms = 3000, name = "ts_ls" })
  end,
})

-- Show diagnostics in location list after save
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
  callback = function(args)
    -- Check if LSP clients are attached before trying to get diagnostics
    local clients = vim.lsp.get_clients({ bufnr = args.buf })
    if #clients > 0 then
      -- Only show location list if there are diagnostics
      local diagnostics = vim.diagnostic.get(args.buf)
      if #diagnostics > 0 then
        vim.diagnostic.setloclist()
      end
    end
  end,
})

-- Go-specific autocommands
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function(args)
    -- Check if gopls is attached
    local clients = vim.lsp.get_clients({ bufnr = args.buf, name = "gopls" })
    if #clients == 0 then
      return
    end

    -- Organize imports and format
    vim.lsp.buf.code_action({
      context = { only = { "source.organizeImports" } },
      apply = true,
    })
    
    -- Wait a bit for imports to be organized, then format
    vim.defer_fn(function()
      vim.lsp.buf.format({ bufnr = args.buf, async = false, timeout_ms = 3000 })
    end, 100)
  end,
})