local M = {
	"nvim-lualine/lualine.nvim",
}

function M.config()
	require("lualine").setup({
		options = {
			theme = "catppuccin",
		},
		sections = {
			lualine_c = { "%S" },
			lualine_x = {
				{
					require("noice").api.status.mode.get,
					cond = require("noice").api.status.mode.has,
				},
			},
		},
	})
end

return M
