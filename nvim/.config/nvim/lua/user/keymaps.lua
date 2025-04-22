local keymap = vim.keymap.set
local opts = { noremap = true, silent = false }
local helpers = require("user.helpers")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Paste from yank register below in NORMAL and VISUAL modes
keymap({ "n", "v" }, "<leader>p", '"0p', { noremap = true, silent = true, desc = "Paste from yank register below" })

-- Paste from yank register above in NORMAL and VISUAL modes
keymap({ "n", "v" }, "<leader>P", '"0P', { noremap = true, silent = true, desc = "Paste from yank register above" })

-- WhichKey shortcut
keymap("n", "<C-Space>", "<cmd>WhichKey \\<space><cr>", opts)

-- Jump forward in jump list (CTRL-I)
keymap("n", "<C-i>", "<C-i>", opts)

-- Better window navigation
keymap("n", "<m-h>", "<C-w>h", vim.tbl_extend("force", opts, { desc = "Move to window on the right" }))
keymap("n", "<m-j>", "<C-w>j", vim.tbl_extend("force", opts, { desc = "Move to window below" }))
keymap("n", "<m-k>", "<C-w>k", vim.tbl_extend("force", opts, { desc = "Move to window above" }))
keymap("n", "<m-l>", "<C-w>l", vim.tbl_extend("force", opts, { desc = "Move to window on the left" }))

-- Better line navigation
keymap("n", "<C-h>", "0", opts)
keymap("n", "<C-l>", "$", opts)

-- Center after search
keymap("n", "n", "nzz", opts)
keymap("n", "N", "Nzz", opts)
keymap("n", "*", "*zz", opts)
keymap("n", "#", "#zz", opts)
keymap("n", "g*", "g*zz", opts)
keymap("n", "g#", "g#zz", opts)

-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Paste without yanking in visual mode
keymap("x", "p", [["_dP]], opts)

-- Delete using black hole register
keymap("n", "<A-d>", '"_d', { noremap = true, silent = true })

-- Show right-click popup menu
keymap("n", "<RightMouse>", "<cmd>:popup mousemenu<CR>", opts)

-- Toggle Hidden Chars
keymap("n", "<leader>c", "<cmd>set invlist<CR>", { noremap = true, silent = false, desc = "Toggle Hidden Chars" })

-- Change using black hole register
keymap("n", "<A-c>", '"_c', { noremap = true, silent = true })

-- Run commands and source files without restarting neovim
keymap("n", "<space>X", function()
  vim.cmd("source %")
  helpers.notify({
    msg = "Sourced current file: " .. vim.fn.expand("%:p"),
    level = vim.log.levels.INFO,
  })
end, vim.tbl_extend("force", opts, { desc = "Source current file" }))
