return {
  cmd = { "rust-analyzer" },
  root_markers = { "Cargo.toml", "Cargo.lock" },
  filetypes = { "rust" },
  settings = {
    ["rust-analyzer"] = {
      check = {
        command = "clippy",
      },
      diagnostics = {
        enable = true,
      },
    },
  },
  -- Merged over Neovim's defaults and blink.cmp's vim.lsp.config("*") capabilities.
  capabilities = {
    workspace = {
      fileOperations = {
        didRename = true,
        willRename = true,
      },
    },
  },
}
