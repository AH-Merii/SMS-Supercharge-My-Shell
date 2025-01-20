local M = { "folke/flash.nvim", event = "VeryLazy" }

function M.config()
	require("flash").setup({
		-- flash.nvim specific configuration options here
		keys = {
			-- Disable the default s and S mappings
			normal = {
				enabled = false,
			},
			visual = {
				enabled = false,
			},
		},
	})

	-- Set up custom keybindings with which-key
	local wk = require("which-key")

	wk.add({
		{ "<leader>s", group = "Flash" }, -- Group name under <leader>s
		{
			mode = { "n", "v" }, -- Apply to both Normal and Visual modes
			{ "<leader>ss", "<cmd>lua require('flash').jump()<cr>", desc = "Flash Jump" },
			{ "<leader>sS", "<cmd>lua require('flash').treesitter()<cr>", desc = "Flash Treesitter" },
		},
	})
end

return M
