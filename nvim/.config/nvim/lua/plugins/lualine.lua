local M = {
	"nvim-lualine/lualine.nvim",
}

vim.opt.showcmdloc='statusline'

function M.config()
  require("lualine").setup({
    options = {
      theme = "catppuccin",
    },
    sections = {
      lualine_c = {'%S'},
    },
  })
end

return M
