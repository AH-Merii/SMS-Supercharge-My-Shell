-- Mason-installed servers are enabled by mason-lspconfig (lua/plugins/mason.lua).
-- Servers that come from a toolchain instead of Mason are enabled below.
-- Per-server overrides live in after/lsp/<name>.lua (see :h lsp-config).
vim.diagnostic.config({
  virtual_text = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
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

-- Servers installed outside Mason (go/rust/zig toolchains, npm/composer packages).
-- This file runs before lazy.nvim, so defer until nvim-lspconfig's lsp/*.lua defaults
-- are on the runtimepath; LazyDone still fires before the first buffer's FileType event.
-- blink.cmp merges its completion capabilities into vim.lsp.config("*") itself.
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function() vim.lsp.enable({ "gopls", "rust_analyzer", "zls", "intelephense", "yamlls" }) end,
})
