require("core.lsp")
require("config.options")
require("config.keymaps")
require("config.autocmds").setup()

require("core.lazy")

-- Late-load overrides after plugins are ready
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function() require("config.helpers") end,
})
