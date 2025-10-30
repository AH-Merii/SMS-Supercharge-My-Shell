-- Mason PATH is handled by core.mason-path
vim.lsp.enable({
  "lua-ls",
  "gopls",
  "zls",
  "ts-ls",
  "rust-analyzer",
  "intelephense",
  "pyrefly",
  "bash-language-server"
})


-- LSP servers are automatically managed by Mason
-- Use :MasonVerify to check which tools are Mason-managed

vim.diagnostic.config({
  virtual_text = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
})

