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
      javascript = { "biomejs" },
      typescript = { "biomejs" },
      javascriptreact = { "biomejs" },
      typescriptreact = { "biomejs" },

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
      terraform = { "tflint", "trivy" },
      dockerfile = { "hadolint" },
    }

    -- Auto-lint on save and text changes
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup
    local user_group = augroup("UserAutocmdsNvimLint", { clear = true })

    -- Linters whose findings a language server also reports, by server name; each runs only where its server is not attached
    local covering_server = { ruff = "ruff", biomejs = "biome", tflint = "tflint", clippy = "rust_analyzer" }

    local function covered(linter_name, bufnr)
      local server = covering_server[linter_name]
      return server ~= nil and #vim.lsp.get_clients({ bufnr = bufnr, name = server }) > 0
    end

    ---@param names? string|string[]
    local function lint_buffer(names)
      lint.try_lint(names, {
        filter = function(linter) return not covered(linter.name, 0) end,
        wrap_linter = function(linter)
          local parse = linter.parser
          if covering_server[linter.name] and type(parse) == "function" then
            -- A run that ends after its server attached reports nothing
            linter.parser = function(output, bufnr, ...) return covered(linter.name, bufnr) and {} or parse(output, bufnr, ...) end
          end
          return linter
        end,
      })
    end

    -- Drop what a linter reported before its server attached
    autocmd("LspAttach", {
      group = user_group,
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        for linter, server in pairs(covering_server) do
          if client and client.name == server then
            vim.diagnostic.reset(lint.get_namespace(linter), ev.buf)
          end
        end
      end,
    })

    autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = user_group,
      callback = function()
        local linters = lint.linters_by_ft[vim.bo.filetype]
        if linters and #linters > 0 then
          lint_buffer()
        end
      end,
    })

    -- 🔹 GitHub Actions workflow linting (actionlint)
    autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      group = user_group,
      pattern = {
        "*/.github/workflows/*.yml",
        "*/.github/workflows/*.yaml",
      },
      callback = function() lint_buffer("actionlint") end,
    })

    -- Manual linting command
    vim.keymap.set("n", "<leader>ll", function()
      lint_buffer()
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
