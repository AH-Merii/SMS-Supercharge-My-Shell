local M = {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
		"3rd/image.nvim",
	},
}

function M.config()
	vim.keymap.set("n", "<leader>n", ":Neotree toggle<CR>")
	require("neo-tree").setup({
		window = {
			mappings = {
				["Y"] = function(state)
					local node = state.tree:get_node()
					local filepath = node:get_id()
					local filename = node.name
					local modify = vim.fn.fnamemodify

					local results = {
						filepath,
						modify(filepath, ":."),
						modify(filepath, ":~"),
						filename,
						modify(filename, ":r"),
						modify(filename, ":e"),
					}

					vim.ui.select(results, { prompt = "Choose to copy to clipboard or Quit with q:" }, function(choice)
						if not choice then
							return -- Do nothing and exit if 'Quit' is selected or if there's no choice (e.g., user pressed escape)
						end

						local i = tonumber(choice:sub(1, 1))
						if not i then
							return
						end -- Additional check in case the choice is not a number
						local result = results[i]
						if not result then
							return
						end -- Check if the result is valid

						vim.fn.setreg('"', result)
						vim.notify("Copied: " .. result)
					end)
				end,
			},
		},
	})
end

return M
