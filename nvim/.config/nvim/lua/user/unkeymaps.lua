-- shortcut to delete keymap
local del = vim.keymap.del

-- Remove 'grn' keymap
pcall(del, "n", "grn")

-- Remove 'gra' keymap in Normal and Visual modes
pcall(del, "n", "gra")
pcall(del, "v", "gra")

-- Remove 'grr' keymap
pcall(del, "n", "grr")

-- Remove 'gc' keymap in Normal and Visual modes
pcall(del, "n", "gc")
pcall(del, "v", "gc")

-- Remove 'gcc' keymap
pcall(del, "n", "gcc")
pcall(del, "v", "gcc")
