-- Neovim configuration entry point
-- Load basic Vim configuration (always works)
require("config.options")
require("config.keymaps")

-- Bootstrap lazy.nvim if needed
require("config.lazy-bootstrap")

-- Load autocommands
require("config.autocmds")

-- Load plugins (gracefully handles missing lazy)
require("plugins")