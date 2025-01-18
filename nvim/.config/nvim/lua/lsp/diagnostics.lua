--- Module to configure LSP diagnostics in Neovim.
local M = {}

--- Default diagnostic configuration.
local icons = require("user.icons")
local default_diagnostic_config = {
  signs = {
    active = true,
    values = {
      { name = "DiagnosticSignError", text = icons.diagnostics.Error },
      { name = "DiagnosticSignWarn",  text = icons.diagnostics.Warning },
      { name = "DiagnosticSignHint",  text = icons.diagnostics.Hint },
      { name = "DiagnosticSignInfo",  text = icons.diagnostics.Information },
    },
  },
  virtual_text = false,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  float = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
}

--- Setup function to configure diagnostics.
--- @param config table|nil: Custom diagnostic configuration. If nil, uses default config.
function M.setup(config)
  config = vim.tbl_deep_extend("force", default_diagnostic_config, config or {})

  -- Apply diagnostic signs if enabled.
  if config.signs.active then
    for _, sign in ipairs(config.signs.values) do
      vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.name })
    end
  end

  -- Apply the diagnostic configuration.
  vim.diagnostic.config(config)
end

return M

