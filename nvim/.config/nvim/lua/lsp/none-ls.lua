local M = {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim"
  }
}

function M.config()
  local null_ls = require "null-ls"

  local formatting = null_ls.builtins.formatting
  local diagnostics =  null_ls.builtins.diagnostics
  local completion = null_ls.builtins.completion

  null_ls.setup {
    debug = false,
    sources = {
      formatting.stylua,
      formatting.prettier,
      formatting.black,
      formatting.isort,
      diagnostics.flake8,
      diagnostics.pylint.with({ prefer_local = ".venv/bin", }),
    },
  }
end

return M
