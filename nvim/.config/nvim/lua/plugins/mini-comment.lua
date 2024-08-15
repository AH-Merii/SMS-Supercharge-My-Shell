local M = { "echasnovski/mini.comment", version = "*", event = "VeryLazy" }

function M.config()
	require("mini.comment").setup({
		mappings = {
			-- Toggle comment (Normal and Visual modes)
			comment = "<leader>/",

			-- Toggle comment on current line
			comment_line = "<leader>/",

			-- Toggle comment on visual selection
			comment_visual = "<leader>/",

			-- Define 'comment' textobject
			textobject = "<leader>/",
		},
	})
end

return M
