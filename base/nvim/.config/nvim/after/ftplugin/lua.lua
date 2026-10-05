local function set_keymaps()
  local opts = { noremap = true, silent = false, buf = 0 } -- buf = 0 applies it only to the current buffer
  local keymap = vim.keymap.set

  keymap("n", "<space>!", ":.lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current line" }))
  keymap("v", "<space>!", ":lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current selection" }))
  keymap("v", "<space>!", ":lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current selection" }))
  keymap("n", "<space>%", "<cmd>source %<CR>", vim.tbl_extend("force", opts, { desc = "Source current file" }))
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<space>!", icon = { icon = "", color = "red" }, real = true },
    })
  end
end

set_keymaps()

local set = vim.opt_local

set.expandtab = true
set.shiftwidth = 2
set.tabstop = 2
