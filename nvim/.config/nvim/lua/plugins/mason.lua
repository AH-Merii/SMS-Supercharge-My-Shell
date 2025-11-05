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
        -- Mojo
        -- "mojo-lsp-server", may become available in the future

        -- Go
        "gopls",

        -- Rust
        "rust_analyzer",

        -- Zig
        "zls",

        -- Bash / shell
        "bashls",

        -- C/C++
        "clangd",

        -- make
        "autotools_ls",

        -- Terraform
        "terraformls",
        "tflint", -- tflint actually behaves like a linter, but mason exposes it as an lspconfig server too

        -- YAML / JSON / TOML
        "yamlls",
        "jsonls",
        "tombi",

        -- Markdown / prose linting-as-LSP
        "marksman",

        -- PHP
        "intelephense",

        -- Docker
        "dockerls",
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
        "prettierd", -- JS/TS/JSON/Markdown formatter
        "stylua", -- Lua formatter
        "goimports", -- Go formatter/imports
        "shfmt", -- Shell formatter
        "pyproject-fmt", -- pyproject.toml formatter
        "taplo", -- toml formatter
        "clang-format", -- C/C++ formatter

        -- Linting / analysis / diagnostics
        "tfsec", -- terraform security
        "eslint_d", -- Fast eslint
        -- "pylint", -- Python linter
        "checkmake", -- make linting
        "ruff", -- Python linter/formatter/organizer
        "golangci-lint", -- Go linter
        "shellcheck", -- Shell linter
        "yamllint", -- YAML linter
        "markdownlint", -- Markdown linter
        "jsonlint", -- JSON linter
        "luacheck", -- Lua linter
        "hadolint", -- docker linter
        "actionlint", -- github actions linter

        -- Debuggers / extra tooling
        "debugpy", -- python
        "delve", -- Go
        "js-debug-adapter", -- TypeScript / JavaScript
      },
    },
  },
}
