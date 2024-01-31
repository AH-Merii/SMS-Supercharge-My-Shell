local M = {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
}

function M.config()
	local wk = require("which-key")

	wk.register({
		n = {
			name = "+noice", -- Optional group name
			d = { "<cmd>NoiceDismiss<CR>", "Dismiss Noice Message" },
		},
	}, { prefix = "<leader>" })

	require("noice").setup({
		opts = {
			routes = {
				{
					filter = { event = "notify", find = "No information available" },
					opts = { skip = true },
				},
			},
		},
		-- you can enable a preset for easier configuration
		presets = {
			lsp_doc_border = false, -- add a border to hover docs and signature help
		},
	})
end

return M
