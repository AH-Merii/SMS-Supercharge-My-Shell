return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo", "FormatWithConform" },
  keys = {
    {
      "<leader>lf",
      function() require("conform").format_buffer({ async = true, quiet = false }) end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },

  opts = {
    formatters_by_ft = {
      -- Web technologies
      javascript = { "prettierd" },
      typescript = { "prettierd" },
      javascriptreact = { "prettierd" },
      typescriptreact = { "prettierd" },
      json = { "prettierd" },
      jsonc = { "prettierd" },
      yaml = { "prettierd" },
      -- docker-compose in Neovim usually has filetype "yaml.docker-compose"
      ["yaml.docker-compose"] = { "prettierd" },
      markdown = { "prettierd" },
      html = { "prettierd" },
      css = { "prettierd" },
      scss = { "prettierd" },

      python = {
        "ruff_fix",
        "ruff_format",
        "ruff_organize_imports",
      },

      -- Shell
      sh = { "shfmt" },
      bash = { "shfmt" },

      -- C/C++
      c = { "clang_format" },
      cpp = { "clang_format" },

      go = { "goimports", "gofmt" },
      lua = { "stylua" },
      rust = { "rustfmt" },
      zig = { "zigfmt" },
      mojo = { "lsp" },

      cmake = { "gersemi" },

      -- Another option for below is I could configure a new filetype toml.pyproject
      -- Maybe down the line I would like to configure yaml.actions etc...
      -- For future reference help: filetype | filetype-detect | new-filetype
      -- TOML: use pyproject-fmt for pyproject.toml, taplo otherwise (if available)
      toml = function(bufnr)
        local c = require("conform")
        local filepath = vim.api.nvim_buf_get_name(bufnr)
        local filename = (filepath ~= "" and vim.fn.fnamemodify(filepath, ":t")) or "<buffer>"

        local py_fmt = c.get_formatter_info("pyproject-fmt", bufnr)
        local taplo = c.get_formatter_info("taplo", bufnr)

        if py_fmt.available and filename == "pyproject.toml" then
          return { "pyproject-fmt" }
        elseif taplo.available then
          return { "taplo" }
        else
          return {}
        end
      end,
    },

    -- Use LSP if no external formatter is configured
    default_format_opts = {
      lsp_format = "fallback",
    },
  },

  config = function(_, opts)
    local c = require("conform")
    c.setup(opts)

    -- use conform for formatexpr
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

    --- Format helper that reports which formatter(s) ran, while still allowing LSP fallback.
    ---@param args { async?: boolean, bufnr?: integer }|nil
    function c.format_buffer(args)
      args = args or {}

      local async = args.async
      if async == nil then
        async = true
      end

      local bufnr = args.bufnr or vim.api.nvim_get_current_buf()

      -- External formatters that conform plans to run (LSP fallback not included here)
      local formatters = c.list_formatters_to_run(bufnr)
      local names = vim.tbl_map(function(f) return f.name end, formatters)

      -- Capture filename for this buffer (independent of current window/buffer)
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      local filename = (filepath ~= "" and vim.fn.fnamemodify(filepath, ":t")) or "<buffer>"
      local ft = vim.bo[bufnr].filetype

      -- Check if there's any LSP attached that can format this buffer (modern API)
      local has_lsp = false
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if client.supports_method and (client:supports_method("textDocument/formatting") or client:supports_method("textDocument/rangeFormatting")) then
          has_lsp = true
          break
        end
      end

      -- Choose label: explicit external formatters, LSP, or none
      local formatter_label
      if #names > 0 then
        formatter_label = table.concat(names, ", ")
      elseif has_lsp then
        formatter_label = "LSP"
      else
        vim.notify(string.format("No formatter or LSP available for filetype (%s)", ft), vim.log.levels.WARN, { title = "Conform" })
        return
      end

      c.format({ async = async, bufnr = bufnr }, function(err, did_edit)
        if err then
          vim.notify(string.format("Formatting failed in %s with %s: %s", filename, formatter_label, err), vim.log.levels.ERROR, { title = "Conform" })
          return
        end

        if not did_edit then
          vim.notify(string.format("No changes made while formatting (%s)", ft), vim.log.levels.INFO, { title = "Conform" })
          return
        end

        vim.notify(string.format("Formatted %s with: %s", filename, formatter_label), vim.log.levels.INFO, { title = "Conform" })
      end)
    end

    vim.api.nvim_create_user_command("FormatWithConform", function() c.format_buffer({ async = true, quiet = false }) end, {
      desc = "Format current buffer with Conform and print formatters used",
    })

    vim.api.nvim_create_user_command("FormatWithConform", function() c.format_buffer({ async = true, quiet = false }) end, {
      desc = "Format current buffer with Conform and print formatters used",
    })

    vim.api.nvim_create_user_command("FormatWithConform", function() c.format_buffer({ async = true, quiet = false }) end, {
      desc = "Format current buffer with Conform and print formatters used",
    })
  end,
}
