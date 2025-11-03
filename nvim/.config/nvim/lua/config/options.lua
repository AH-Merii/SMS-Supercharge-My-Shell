-- 🏁 Leader Keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable Lazydev for vim globals
vim.g.lazydev_enabled = true

-- ⚙️ General Settings
vim.opt.termguicolors = true
vim.opt.fileencoding = "utf-8"
vim.opt.confirm = true -- Confirm before exiting modified buffer
vim.opt.timeoutlen = 1000
vim.opt.jumpoptions = "view" -- Replaces BufReadPost autocmd
vim.opt.autoread = true -- Auto-reload files
vim.opt.inccommand = "split" -- Live preview for substitutions

-- 💾 Files, Backup & Undo
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true

-- 📋 Clipboard & Mouse
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

-- 🧭 UI & Appearance
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 4
vim.opt.cmdheight = 1
vim.opt.laststatus = 3 -- Global statusline
vim.opt.showcmdloc = "statusline" -- Show commands in statusline
vim.opt.pumheight = 10
vim.opt.pumblend = 10 -- Popup menu transparency
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
