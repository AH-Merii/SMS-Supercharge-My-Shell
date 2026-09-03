local function set_keymaps()
  local opts = { noremap = true, silent = false, buffer = true } -- buffer = true, ensures that it is only applied for current buffer
  local keymap = vim.keymap.set

  keymap("n", "<space>!", ":.lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current line" }))
  keymap("v", "<space>!", ":lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current selection" }))
  keymap("v", "<space>!", ":lua<CR>", vim.tbl_extend("force", opts, { desc = "Execute current selection" }))
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({
      { "<space>!", icon = { icon = "", color = "red" } },
    })
  end
end

set_keymaps()

local set = vim.opt_local

set.expandtab = true
set.shiftwidth = 2
set.tabstop = 2
