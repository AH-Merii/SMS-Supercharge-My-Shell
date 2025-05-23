--- Module for user-defined Neovim commands.
local M = {}

--- Registers user-defined commands.
function M.setup()
  -- Toggle debug mode for helpers module
  vim.api.nvim_create_user_command(
    "ToggleDebug",
    function()
      require("user.helpers").toggle_debug()
    end,
    { desc = "Toggle debug mode for helpers module" }
  )

  -- Reload Neovim configuration
  vim.api.nvim_create_user_command(
    "ReloadConfig",
    function()
      vim.cmd("source $MYVIMRC")
      vim.notify("Configuration reloaded!", vim.log.levels.INFO)
    end,
    { desc = "Reload Neovim configuration" }
  )

  -- Shows current file path
  vim.api.nvim_create_user_command("ShowFilePath", function()
    local file_path = vim.fn.expand("%:p")
    print("Current file path: " .. file_path)
  end, {})
end

return M
