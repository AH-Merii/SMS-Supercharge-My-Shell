-- 🏁 Leader Keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable Lazydev for vim globals
vim.g.lazydev_enabled = true

-- ⚙️ General Settings
vim.opt.termguicolors = true
vim.opt.fileencoding = "utf-8"
vim.opt.confirm = true -- Confirm before exiting modified buffer
vim.opt.modeline = false -- Don't evaluate modelines from (untrusted) files
vim.opt.timeoutlen = 500 -- How much time nvim waits for the next command (example sa: for mini.surround)
vim.opt.jumpoptions = "view" -- Restores both cursor and window view (scroll, folds, etc.) between jumps
vim.opt.autoread = true -- Auto-reload files
vim.opt.inccommand = "split" -- Live preview for substitutions %s/text/new_text/

-- 💾 Files, Backup & Undo
vim.opt.undofile = true

-- 📋 Clipboard & Mouse
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a" -- enable mouse in (a)ll modes

-- 🧭 UI & Appearance
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 4
vim.opt.scrolloff = 999
vim.opt.sidescrolloff = 8
vim.opt.virtualedit = "block" -- Block mode cursor positioning
vim.opt.list = true
vim.opt.listchars = {
  space = "·",
  tab = "->",
  trail = "󰄛",
  eol = "¶",
  extends = "»",
  precedes = "«",
  nbsp = "󰛗",
  lead = ".",
}

-- With cmdheight=0 there is no last line to draw the pending command in, so
-- send it to the statusline instead (lualine needs a %S component to show it)
vim.opt.cmdheight = 0
vim.o.showcmd = true
vim.o.showcmdloc = "statusline" -- show partial commands (e.g. 44j) in the statusline

-- make the hidden chars foreground color more subtle
vim.cmd([[
highlight NonText guifg=#cccccc ctermfg=lightgray
highlight SpecialKey guifg=#cccccc ctermfg=lightgray
]])

-- 󰞷 Editing & Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.breakindent = true
vim.opt.wrap = false

--  Search
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

--  Splits & Windows
vim.opt.splitbelow = true
vim.opt.splitright = true

-- 🗂 Filetype Detection
vim.filetype.add({
  extension = { env = "dotenv" },
  filename = { [".env"] = "dotenv", ["env"] = "dotenv" },
  pattern = {
    ["[jt]sconfig.*.json"] = "jsonc",
    ["%.env%.[%w_.-]+"] = "dotenv",
  },
})
