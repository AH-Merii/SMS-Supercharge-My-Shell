local function set_lua_keymaps()
	local opts = { noremap = true, silent = false, buffer = true } -- buffer = true, ensures that it is only applied for current buffer
	local keymap = vim.keymap.set

	keymap("n", "<space>x", ":.lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current line" }))
	keymap("v", "<space>x", ":lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current line" }))
end

set_lua_keymaps()

local set = vim.opt_local

set.shiftwidth = 2
