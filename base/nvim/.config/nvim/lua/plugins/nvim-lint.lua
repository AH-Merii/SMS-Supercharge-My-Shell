return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- Configure linters by filetype (using Mason-managed tools).
    -- ruff, biome and tflint are not listed: mason-lspconfig runs them as LSP
    -- servers, and rust-analyzer already runs clippy (after/lsp/rust_analyzer.lua),
    -- so linting them here would report every finding twice.
    lint.linters_by_ft = {
      -- Go
      go = { "golangcilint" },

      lua = { "luacheck" },

      -- Shell
      sh = { "shellcheck" },
      bash = { "shellcheck" },

      -- Other
      markdown = { "markdownlint" },
      yaml = { "yamllint" },
      json = { "jsonlint" },
      make = { "checkmake" },
      terraform = { "trivy" },
      dockerfile = { "hadolint" },
    }

    -- Auto-lint on open, save and leaving insert mode
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup
    local user_group = augroup("UserAutocmdsNvimLint", { clear = true })

    autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      group = user_group,
      callback = function()
        local linters = lint.linters_by_ft[vim.bo.filetype]
        if linters and #linters > 0 then
          lint.try_lint()
        end
      end,
    })

    -- 🔹 GitHub Actions workflow linting (actionlint)
    autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      group = user_group,
      -- Leading "*" so the pattern matches anywhere in the full path (:h autocmd-pattern)
      pattern = {
        "*/.github/workflows/*.yml",
        "*/.github/workflows/*.yaml",
      },
      callback = function() lint.try_lint("actionlint") end,
    })

    -- Manual linting command
    vim.keymap.set("n", "<leader>ll", function()
      lint.try_lint()
      vim.notify("Linting...", vim.log.levels.INFO, { title = "nvim-lint" })
    end, { desc = "Trigger linting for current file" })

    -- Show linter status
    vim.keymap.set("n", "<leader>li", function()
      local linters = lint.linters_by_ft[vim.bo.filetype] or {}
      if #linters == 0 then
        print("No linters configured for filetype: " .. vim.bo.filetype)
      else
        print("Linters for " .. vim.bo.filetype .. ": " .. table.concat(linters, ", "))
      end
    end, { desc = "Show available linters for current filetype" })
  end,
}
