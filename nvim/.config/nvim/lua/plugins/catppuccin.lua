local M = {
  "catppuccin/nvim",
  lazy = false,
  name = "catppuccin",
  priority = 1000,
}

function M.config()
  vim.cmd.colorscheme "catppuccin"
end

return M
