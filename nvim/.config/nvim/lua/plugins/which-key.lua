local M = {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = false
		-- vim.o.timeoutlen = 100
	end,
}

function M.config()
	local wk = require("which-key")

	wk.setup({
		plugins = {
			marks = true,
			registers = true,
			spelling = {
				enabled = true,
				suggestions = 20,
			},
		},
		window = { -- Updated from `win` to `window` as per deprecation notice
			border = "rounded",
			position = "bottom",
			padding = { 2, 2, 2, 2 },
		},
	})

	wk.add({
		{ "<leader>q", "<cmd>confirm q<CR>", desc = "Quit" },
		{ "<leader>w", "<cmd>confirm w<CR>", desc = "Save" },
		{ "<leader>h", "<cmd>nohlsearch<CR>", desc = "NOHL" },
		{ "<leader>W", "<cmd>noautocmd w<CR>", desc = "Save w/o format" },
		{ "<leader>Q", "<cmd>noautocmd wq<CR>", desc = "Save & Quit w/o format" },
		{ "<leader>;", "<cmd>tabnew | terminal<CR>", desc = "Term" },
		{ "<leader>v", "<cmd>vsplit<CR>", desc = "Split" },

		{ "<leader>d", group = "Debug" },
		{ "<leader>g", group = "Git" },
		{ "<leader>t", group = "Test" },
	}, {
		mode = "n", -- NORMAL mode
		prefix = "<leader>",
	})
end

return M
