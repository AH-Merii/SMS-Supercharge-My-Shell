return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- Configure linters by filetype (using Mason-managed tools)
    lint.linters_by_ft = {
      -- Go
      go = { "golangcilint" },

      -- JavaScript/TypeScript
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },

      lua = { "luacheck" },

      -- Shell
      sh = { "shellcheck" },
      bash = { "shellcheck" },

      python = { "ruff" },
      rust = { "clippy" },

      -- Other
      markdown = { "markdownlint" },
      yaml = { "yamllint" },
      json = { "jsonlint" },
      make = { "checkmake" },
      terraform = { "tflint", "tfsec" },
      dockerfile = { "hadolint" },
    }

    -- Auto-lint on save and text changes
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup
    local user_group = augroup("UserAutocmdsNvimLint", { clear = true })

    autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
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
      pattern = {
        ".github/workflows/*.yml",
        ".github/workflows/*.yaml",
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
