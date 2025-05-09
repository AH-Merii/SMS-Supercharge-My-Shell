-- lua/plugins/conform.lua
local M = {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {}, -- keep empty if you don't need opts elsewhere
}

function M.config()
	local conform = require("conform")

	conform.setup({
		format_on_save = {
			timeout_ms = 500,
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			lua = { "stylua", lsp_format = "fallback" },
			python = { "ruff_organize_imports", "ruff_fix", "ruff_format" },
			rust = { "rustfmt", lsp_format = "fallback" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			bash = { "shfmt", "shellcheck" },
			zsh = { "shfmt", "shellcheck" },
			sh = { "shfmt", "shellcheck" },
		},
	})

	vim.keymap.set({ "n", "v" }, "<leader>lf", function()
		conform.format({ async = true })
	end, { desc = "Format (conform.nvim)" })
end

return M
