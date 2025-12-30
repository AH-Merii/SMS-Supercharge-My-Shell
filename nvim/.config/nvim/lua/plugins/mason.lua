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
}

local ensure_installed_lsps = {

  -- LSP *server* names (not Mason package names)
  "pyrefly",
  "lua_ls",
  "fish_lsp",
  "marksman",
  "ts_ls",
}

return {
  ---------------------------------------------------------------------------
  -- Mason core
  ---------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
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
      automatic_installation = true,
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
  -- DAP (Python)
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-dap",
    optional = true,
  },

  ---------------------------------------------------------------------------
  -- Mason integration for DAP (optional)
  ---------------------------------------------------------------------------
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    dependencies = {
      "mason-org/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    opts = {
      automatic_installation = true,
    },
  },

  ---------------------------------------------------------------------------
  -- Mason integration for linters/formatters (optional)
  ---------------------------------------------------------------------------
  {
    "rshkarin/mason-nvim-lint",
    optional = true,
    dependencies = { "mason-org/mason.nvim" },
    opts = {},
  },

  {
    "zapling/mason-conform.nvim",
    optional = true,
    dependencies = { "mason-org/mason.nvim" },
    opts = {},
  },

  ---------------------------------------------------------------------------
  -- Optional: language-specific tool bundles
  ---------------------------------------------------------------------------
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
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
