return {
  -- LSP servers
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = {
          ui = {
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗",
            },
          },
        },
      },
      "neovim/nvim-lspconfig",
    },
    opts = {
      -- LSP servers mason should install for us.
      -- These names are lspconfig server names, not raw mason package names.
      ensure_installed = {
        -- Web / frontend
        "ts_ls", -- typescript / javascript
        "html",
        "cssls",
        "tailwindcss",
        "svelte",
        "emmet_ls",
        "eslint",

        -- Lua
        "lua_ls",

        -- GraphQL / Prisma
        "graphql",
        "prismals",

        -- Python
        "pyright",

        -- Go
        "gopls",

        -- Rust
        "rust_analyzer",

        -- Zig
        "zls",

        -- Bash / shell
        "bashls",

        -- Terraform
        "terraformls",
        "tflint", -- tflint actually behaves like a linter, but mason exposes it as an lspconfig server too

        -- YAML / JSON
        "yamlls",
        "jsonls",

        -- PHP
        "intelephense",

        -- (optional) Markdown / prose linting-as-LSP
        "marksman",
      },
    },
  },

  -- Formatters, linters, debuggers, etc.
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
    opts = {
      ensure_installed = {
        -- Formatting
        "prettier", -- JS/TS/JSON/Markdown formatter
        "stylua", -- Lua formatter
        "goimports", -- Go formatter/imports
        "shfmt", -- Shell formatter

        -- Linting / analysis / diagnostics
        "eslint_d", -- Fast eslint
        "pylint", -- Python linter
        "ruff", -- Python linter/formatter/organizer
        "golangci-lint", -- Go linter
        "shellcheck", -- Shell linter
        "tflint", -- Terraform linter
        "yamllint", -- YAML linter
        "markdownlint", -- Markdown linter
        "jsonlint", -- JSON linter
        "luacheck", -- Lua linter

        -- Debuggers / extra tooling
        "debugpy", -- Python
        "delve", -- Go
        "js-debug-adapter", -- TypeScript / JavaScript
      },
    },
  },
}
