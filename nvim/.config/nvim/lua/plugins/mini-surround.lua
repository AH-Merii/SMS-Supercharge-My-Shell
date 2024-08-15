local M = { "echasnovski/mini.surround", version = "*", event = "VeryLazy" }

function M.config()
	-- Disable default 's' command in all mode
	vim.api.nvim_set_keymap("", "s", "<Nop>", { noremap = true, silent = true })

	require("mini.surround").setup({})

end

return M
