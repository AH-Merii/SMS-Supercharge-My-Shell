local M = {
	"stevearc/oil.nvim",
	opts = {},
	-- Optional dependencies
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
}

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

return M
