-- Always-installed tools
local ensure_installed_formatters_linters = {
  -- Lua
  "stylua",
  "luacheck",

  -- Python
  "ruff",
  "debugpy",
  "pyproject-fmt",

  -- Markdown / prose
  "markdownlint",

  -- Global formatter
  "prettierd",

  -- Spelling/Languague
  "codespell",
}

-- Always installed LSPs
local ensure_installed_lsps = {
  -- LSP *server* names (not Mason package names)
  "pyrefly",
  "lua_ls",
  "stylua",
  "marksman",
  "ts_ls",
}

return {
  ---------------------------------------------------------------------------
  -- Mason core
  ---------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
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

  ---------------------------------------------------------------------------
  -- LSP bridge
  ---------------------------------------------------------------------------
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      -- LSP *server* names (not Mason package names)
      ensure_installed = ensure_installed_lsps,
      -- Automatically enable installed servers
      automatic_enable = true,
    },
  },

  ---------------------------------------------------------------------------
  -- Always-install tools (Python / Lua / Markdown / TS)
  ---------------------------------------------------------------------------
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = ensure_installed_formatters_linters,
    },
  },

  ---------------------------------------------------------------------------
  -- On-demand install/update of other LSPs, formatters, linters, DAPs
  ---------------------------------------------------------------------------
  {
    "owallb/mason-auto-install.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      -- Mason *package* names
      -- LSP servers: filetypes are autodetected from LSP config
      -- Non-LSP tools: need explicit filetypes
      packages = {
        ---------------------------------------------------------------------
        -- Web / frontend
        ---------------------------------------------------------------------
        {
          "eslint_d",
          filetypes = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
          },
        },

        "html-lsp",
        "css-lsp",

        "tailwindcss-language-server",
        "svelte-language-server",
        "emmet-ls",

        -- ESLint LSP (separate from eslint_d)
        "eslint-lsp",

        ---------------------------------------------------------------------
        -- GraphQL / Prisma
        ---------------------------------------------------------------------
        "graphql-language-service-cli",
        "prisma-language-server",

        ---------------------------------------------------------------------
        -- Go
        ---------------------------------------------------------------------
        {
          "gopls",
          -- filetypes from LSP config; only deps are listed here
          dependencies = {
            { "goimports", filetypes = { "go" } },
            { "golangci-lint", filetypes = { "go" } },
            { "delve", filetypes = { "go" } },
          },
        },

        ---------------------------------------------------------------------
        -- Rust / Zig
        ---------------------------------------------------------------------
        "rust-analyzer",
        "zls",

        ---------------------------------------------------------------------
        -- Shell / Bash
        ---------------------------------------------------------------------
        {
          "bash-language-server",
          dependencies = {
            { "shfmt", filetypes = { "sh", "bash", "zsh" } },
            { "shellcheck", filetypes = { "sh", "bash", "zsh" } },
          },
        },

        ---------------------------------------------------------------------
        -- C / C++
        ---------------------------------------------------------------------
        {
          "clangd",
          dependencies = {
            { "clang-format", filetypes = { "c", "cpp", "objc", "objcpp" } },
          },
        },

        ---------------------------------------------------------------------
        -- make
        ---------------------------------------------------------------------
        "autotools-language-server",
        { "checkmake", filetypes = { "make" } },

        ---------------------------------------------------------------------
        -- Terraform
        ---------------------------------------------------------------------
        {
          "terraform-ls",
          dependencies = {
            { "tflint", filetypes = { "terraform", "tf", "hcl" } },
            { "tfsec", filetypes = { "terraform", "tf", "hcl" } },
          },
        },

        ---------------------------------------------------------------------
        -- YAML / JSON / TOML
        ---------------------------------------------------------------------
        {
          "yaml-language-server",
          dependencies = {
            { "yamllint", filetypes = { "yaml", "yml" } },
            { "actionlint", filetypes = { "yaml", "yml" } },
          },
        },

        {
          "json-lsp",
          dependencies = {
            { "jsonlint", filetypes = { "json", "jsonc" } },
          },
        },

        {
          "tombi", -- TOML LSP / formatter / linter
          dependencies = {
            { "taplo", filetypes = { "toml" } }, -- used as formatter
          },
        },

        ---------------------------------------------------------------------
        -- PHP
        ---------------------------------------------------------------------
        "intelephense",

        ---------------------------------------------------------------------
        -- Docker
        ---------------------------------------------------------------------
        {
          "dockerfile-language-server",
          dependencies = {
            { "hadolint", filetypes = { "dockerfile" } },
          },
        },
        -- docker-compose LSP
        "docker-compose-language-service",

        ---------------------------------------------------------------------
        -- TYPST
        ---------------------------------------------------------------------
        {
          "tinymist",
          dependencies = {
            { "typstyle", filetypes = { "typst" } },
          },
        },
      },
    },
  },
}
