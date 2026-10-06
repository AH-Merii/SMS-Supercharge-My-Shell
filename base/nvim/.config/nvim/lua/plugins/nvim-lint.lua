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

    -- Skip linters Mason has not installed yet instead of reporting ENOENT
    local function installed(linter)
      local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
      return vim.fn.executable(cmd) == 1
    end

    -- Linters whose findings a language server also reports, by server name; each runs only where its server is not attached
    local covering_server = { ruff = "ruff", biomejs = "biome", tflint = "tflint", clippy = "rust_analyzer" }

    local function covered(linter_name, bufnr)
      local server = covering_server[linter_name]
      return server ~= nil and #vim.lsp.get_clients({ bufnr = bufnr, name = server }) > 0
    end

    ---@param names? string|string[]
    ---@param filter? fun(linter: lint.Linter): boolean
    local function lint_buffer(names, filter)
      lint.try_lint(names, {
        filter = function(linter) return not covered(linter.name, 0) and (not filter or filter(linter)) end,
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
        if #lint._resolve_linter_by_ft(vim.bo.filetype) > 0 then
          lint_buffer(nil, installed)
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
      callback = function() lint_buffer("actionlint", installed) end,
    })

    -- Lint every loaded buffer again when Mason installs a package; BufWritePost runs both autocmds above
    require("mason-registry"):on(
      "package:install:success",
      vim.schedule_wrap(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            vim.api.nvim_buf_call(buf, function() vim.api.nvim_exec_autocmds("BufWritePost", { group = user_group, buffer = buf, modeline = false }) end)
          end
        end
      end)
    )

    ---@param buf integer
    local function map_lint_keys(buf)
      pcall(vim.keymap.del, "n", "<leader>ll", { buffer = buf })
      pcall(vim.keymap.del, "n", "<leader>li", { buffer = buf })
      -- The lookup try_lint does when lint_buffer() names no linters
      local names = lint._resolve_linter_by_ft(vim.bo[buf].filetype)
      if #names == 0 then
        return
      end

      -- Manual linting command, while lint_buffer() would run at least one linter
      if vim.iter(names):any(function(name) return not covered(name, buf) end) then
        vim.keymap.set("n", "<leader>ll", function()
          lint_buffer(nil, installed)
          vim.notify("Linting...", vim.log.levels.INFO, { title = "nvim-lint" })
        end, { buffer = buf, desc = "Trigger linting for current file" })
      end

      -- Show linter status
      vim.keymap.set("n", "<leader>li", function()
        local linters = vim.tbl_map(function(name)
          return covered(name, buf) and ("%s (reported by the %s server)"):format(name, covering_server[name]) or name
        end, lint._resolve_linter_by_ft(vim.bo[buf].filetype))
        if #linters == 0 then
          print("No linters configured for filetype: " .. vim.bo.filetype)
        else
          print("Linters for " .. vim.bo.filetype .. ": " .. table.concat(linters, ", "))
        end
      end, { buffer = buf, desc = "Show available linters for current filetype" })
    end

    autocmd({ "FileType", "LspAttach" }, { group = user_group, callback = function(ev) map_lint_keys(ev.buf) end })
    autocmd("LspDetach", {
      group = user_group,
      callback = function(ev)
        -- The detaching client still counts as attached while LspDetach runs
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            map_lint_keys(ev.buf)
          end
        end)
      end,
    })
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        map_lint_keys(buf)
      end
    end
  end,
}
