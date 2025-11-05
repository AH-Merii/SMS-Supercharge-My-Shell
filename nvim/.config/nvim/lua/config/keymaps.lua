local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

-- Helper to add desc to opts
local function desc(description) return vim.tbl_extend("force", { noremap = true, silent = false }, { desc = description }) end
local function silent_desc(description) return vim.tbl_extend("force", opts, { desc = description }) end

-- Move selected line / block of text in visual mode
keymap("v", "J", ":m '>+1<CR>gv=gv", silent_desc("Move line down"))
keymap("v", "K", ":m '<-2<CR>gv=gv", silent_desc("Move line up"))

-- Fast saving
keymap("n", "<leader>w", ":write!<CR>", silent_desc("Save file"))
keymap("n", "<leader>q", ":q!<CR>", silent_desc("Quit without saving"))

-- Remap for dealing with visual line wraps
keymap("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Move up (respects wraps)" })
keymap("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Move down (respects wraps)" })

-- Better indenting (with temporary Snacks indent animation disable)
keymap("v", "<", function()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.indent then
    local buf = vim.api.nvim_get_current_buf()
    local prev_state = vim.b[buf].snacks_indent_animate
    vim.b[buf].snacks_indent_animate = false

    -- Perform normal indent and stay in visual mode
    vim.cmd("normal! <gv")

    -- Restore animation after short delay
    vim.defer_fn(function() vim.b[buf].snacks_indent_animate = prev_state end, 30)
  else
    vim.cmd("normal! <gv")
  end
end, desc("Indent left"))

keymap("v", ">", function()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.indent then
    local buf = vim.api.nvim_get_current_buf()
    local prev_state = vim.b[buf].snacks_indent_animate
    vim.b[buf].snacks_indent_animate = false

    vim.cmd("normal! >gv")

    vim.defer_fn(function() vim.b[buf].snacks_indent_animate = prev_state end, 30)
  else
    vim.cmd("normal! >gv")
  end
end, desc("Indent right"))

-- Paste over currently selected text without yanking it
keymap("v", "p", '"_dP', silent_desc("Paste without yanking"))
keymap("v", "P", '"_dP', silent_desc("Paste without yanking"))

-- Panes resizing
keymap("n", "+", ":vertical resize +5<CR>", silent_desc("Increase width"))
keymap("n", "-", ":vertical resize -5<CR>", silent_desc("Decrease width"))
keymap("n", "=", ":resize +5<CR>", silent_desc("Increase height"))
keymap("n", "_", ":resize -5<CR>", silent_desc("Decrease height"))

-- Split line with X
keymap("n", "X", ":keeppatterns substitute/\\s*\\%#\\s*/\\r/e <bar> normal! ==^<cr>", silent_desc("Split line at cursor"))

-- Select all
keymap("n", "<C-a>", "ggVG", silent_desc("Select all"))

-- Clear search highlight
keymap("n", "<Esc>", ":nohlsearch<CR>", silent_desc("Clear search highlight"))

-- Change using black hole register
keymap("n", "<A-c>", '"_c', silent_desc("Change to black hole register"))

-- Delete using black hole register
keymap("n", "<A-d>", '"_d', silent_desc("Delete to black hole register"))

-- Run commands and source files without restarting neovim
keymap("n", "<space>%", "<cmd>source %<CR>", desc("Source current file"))
