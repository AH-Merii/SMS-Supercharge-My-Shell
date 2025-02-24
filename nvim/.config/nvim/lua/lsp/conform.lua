local M = {
  'stevearc/conform.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {},
}

function M.config()
  local conform = require("conform")

  conform.setup({
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
    formatters_by_ft = {
      lua = { "stylua" },
      -- python = { "isort", "black" },
      rust = { "rustfmt", lsp_format = "fallback" },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      bash = { 'shfmt', 'shellcheck' },
      zsh = { 'shfmt', 'shellcheck' },
      sh = { 'shfmt', 'shellcheck' },

    }
  })
end

return M
