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

  wk.add({
    { "<leader>n", group = "noice" }, -- Define the "noice" group with leader key prefix
    { "<leader>nd", "<cmd>NoiceDismiss<CR>", desc = "Dismiss Noice Message" }, -- Define the keybinding within the "noice" group
  })

	require("noice").setup({
		opts = {
			routes = {
				{
					filter = { event = "notify", find = "No information available" },
					opts = { skip = true },
				},
			},
		},
		lsp = {
			progress = {
				enabled = false,
				-- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
				-- See the section on formatting for more details on how to customize.
				--- @type NoiceFormat|string
				format = "lsp_progress",
				--- @type NoiceFormat|string
				format_done = "lsp_progress_done",
				throttle = 1000 / 30, -- frequency to update lsp progress message
				view = "mini",
			},
		},
		-- you can enable a preset for easier configuration
		presets = {
			lsp_doc_border = false, -- add a border to hover docs and signature help
		},
	})
end

return M
