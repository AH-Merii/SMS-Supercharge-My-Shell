-- Disable automatic comment insertion on new lines when entering a buffer window
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
	callback = function()
		vim.cmd("set formatoptions-=cro")
	end,
})

-- Set up specific behaviors for certain file types (like netrw, help, git, etc.)
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = {
		"netrw", -- File explorer
		"Jaq", -- Jaq plugin
		"qf", -- Quickfix list
		"git", -- Git-related buffers
		"help", -- Help documentation
		"man", -- Man pages
		"lspinfo", -- LSP information
		"oil", -- Oil plugin
		"spectre_panel", -- Spectre plugin
		"lir", -- Lir plugin
		"DressingSelect", -- Dressing select UI
		"tsplayground", -- Treesitter playground
		"", -- Catch-all empty pattern
	},
	callback = function()
		-- Map 'q' to close the buffer and prevent it from being listed in buffer list
		vim.cmd([[
			nnoremap <silent> <buffer> q :close<CR>
			set nobuflisted
		]])
	end,
})

-- Automatically quit Neovim when entering the command-line window
vim.api.nvim_create_autocmd({ "CmdWinEnter" }, {
	callback = function()
		vim.cmd("quit")
	end,
})

-- Resize all windows equally across tabs when Neovim is resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- Check for changes to the file when entering a buffer window and reload if necessary
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
	pattern = { "*" },
	callback = function()
		vim.cmd("checktime")
	end,
})

-- Highlight yanked (copied) text briefly for visual feedback
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	callback = function()
		vim.highlight.on_yank({ higroup = "Visual", timeout = 40 })
	end,
})

-- Format the file before saving it, using specific LSP clients like efm or null-ls
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function()
		vim.lsp.buf.format({
			async = false,
		})
	end,
})

-- Enable line wrapping and spell checking for specific file types (e.g., gitcommit, markdown)
vim.api.nvim_create_autocmd({ "FileType" }, {
	pattern = { "gitcommit", "markdown", "NeogitCommitMessage" },
	callback = function()
		vim.opt_local.wrap = true -- Enable line wrap
		vim.opt_local.spell = true -- Enable spell check
	end,
})

-- Automatically unlink the current snippet in LuaSnip when cursor is held over it
vim.api.nvim_create_autocmd({ "CursorHold" }, {
	callback = function()
		local status_ok, luasnip = pcall(require, "luasnip")
		if not status_ok then
			return
		end
		if luasnip.expand_or_jumpable() then
			-- Unlink the current snippet silently to clean up the state
			vim.cmd([[silent! lua require("luasnip").unlink_current()]])
		end
	end,
})
