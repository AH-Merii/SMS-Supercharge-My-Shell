--- Module for setting up Neovim's LSP configuration.
local M = {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    {
      "folke/lazydev.nvim",
      ft = "lua", -- Only load for Lua files
      opts = {
        library = {
          -- Load luvit types when "vim.uv" is found
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },
  },
}

local helpers = require("user.helpers") -- Load the helpers module for notifications
require("lsp.diagnostics").setup()      -- Configure diagnostics (e.g., diagnostic signs)

local lsp_keymaps = require("lsp.keymaps")

--- Handles LSP client attachment to a buffer.
--- @param client table: The LSP client object.
--- @param bufnr number: The buffer number.
function M.on_attach(client, bufnr)
  lsp_keymaps.set_all_lsp_keymaps(bufnr) -- Set keymaps for supported LSP features
  helpers.notify("LSP attached to buffer " .. bufnr .. " with client " .. client.name, vim.log.levels.DEBUG, true)
end

--- Toggles inlay hints for the current buffer.
M.toggle_inlay_hints = function()
  local current_state = vim.lsp.inlay_hint.is_enabled() and "enabled" or "disabled"
  helpers.notify(
    string.format("Inlay hints are currently %s. Toggling state.", current_state),
    vim.log.levels.DEBUG,
    true
  )
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end

--- Configures LSP client capabilities.
--- @return table: The updated capabilities.
function M.common_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  helpers.notify("Configured LSP client capabilities.", vim.log.levels.DEBUG, true)
  return capabilities
end

local wk = require("which-key")

--- Main configuration function for the module.
function M.config()
  -- Set up which-key mappings for LSP commands
  wk.add({
    { "<leader>l",  group = "LSP" },
    { "<leader>li", "<cmd>LspInfo<cr>",                                        desc = "Info",            mode = "n" },
    { "<leader>lh", "<cmd>lua require('lsp.config').toggle_inlay_hints()<cr>", desc = "Hints",           mode = "n" },
    { "<leader>ll", "<cmd>lua vim.lsp.codelens.run()<cr>",                     desc = "CodeLens Action", mode = "n" },
    { "<leader>lq", "<cmd>lua vim.diagnostic.setloclist()<cr>",                desc = "Quickfix",        mode = "n" },
  })

  -- Configure global handlers with rounded borders
  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
  vim.lsp.handlers["textDocument/signatureHelp"] =
      vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
  require("lspconfig.ui.windows").default_options.border = "rounded"

  local lspconfig = require("lspconfig")
  local servers = require("lsp.servers")

  for _, server in pairs(servers) do
    local opts = {
      on_attach = M.on_attach,
      capabilities = M.common_capabilities(),
    }

    -- Attempt to load server-specific settings
    local require_ok, settings = pcall(require, "lsp.settings." .. server)
    if require_ok then
      opts = vim.tbl_deep_extend("force", settings, opts)
      helpers.notify("Loaded settings for LSP server: " .. server, vim.log.levels.DEBUG, true)
    else
      helpers.notify("Could not find settings for LSP server: " .. server, vim.log.levels.WARN)
    end

    -- Set up the server with the configured options
    lspconfig[server].setup(opts)
    helpers.notify("Configured LSP server: " .. server, vim.log.levels.INFO)
  end
end

return M
