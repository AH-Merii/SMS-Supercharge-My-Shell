local function set_keymaps()
  local opts = { noremap = true, silent = false, buf = 0 } -- buf = 0 applies it only to the current buffer
  local keymap = vim.keymap.set

  keymap("n", "<space>!", ":.lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current line" }))
  keymap("x", "<space>!", ":lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current selection" }))
  keymap("n", "<space>%", "<cmd>source %<CR>", vim.tbl_extend("force", opts, { desc = "Source current file" }))
end

set_keymaps()

local set = vim.opt_local

set.expandtab = true
set.shiftwidth = 2
set.tabstop = 2
