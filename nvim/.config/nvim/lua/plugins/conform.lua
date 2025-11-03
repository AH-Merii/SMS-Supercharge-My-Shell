return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>lf",
      function()
        local conform = require("conform")
        local bufnr = vim.api.nvim_get_current_buf()

        -- Get the list of formatters that will run for this buffer
        local formatters = conform.list_formatters_to_run(bufnr)
        local names = vim.tbl_map(function(f)
          return f.name
        end, formatters)
        local formatter_list = #names > 0 and table.concat(names, ", ") or "none"

        conform.format({ async = true }, function(err, did_edit)
          if not err and did_edit then
            vim.notify(string.format("Formatted with: %s", formatter_list), vim.log.levels.INFO, { title = "Conform" })
          elseif err then
            vim.notify("Formatting failed: " .. err, vim.log.levels.ERROR, { title = "Conform" })
          end
        end)
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      -- Go
      go = { "goimports", "gofmt" },

      -- Lua
      lua = { "stylua" },

      -- Web technologies
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },

      -- Python
      python = {
        -- To fix auto-fixable lint errors.
        "ruff_fix",
        -- To run the Ruff formatter.
        "ruff_format",
        -- To organize the imports.
        "ruff_organize_imports",
      },

      -- Shell
      sh = { "shfmt" },
      bash = { "shfmt" },

      -- Other (system tools)
      rust = { "rustfmt" }, -- comes with Rust installation
    },
    default_format_opts = {
      lsp_format = "fallback",
    },
    -- format_on_save = {
    --     timeout_ms = 1000,
    --     lsp_format = "fallback",
    -- },
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
