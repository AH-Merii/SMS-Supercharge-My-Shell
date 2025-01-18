local M = {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvimtools/none-ls-extras.nvim", -- Add the extras plugin
	},
}

function M.config()
	local nls = require("null-ls")

	local formatting = nls.builtins.formatting
	local diagnostics = nls.builtins.diagnostics

	nls.setup({
		debug = true,
		sources = {
			formatting.stylua,
			formatting.prettier,
			-- formatting.black,
			-- formatting.ruff,
			-- formatting.isort,
			diagnostics.hadolint,
			require("none-ls.diagnostics.flake8"),
			diagnostics.pylint.with({
				prefer_local = ".venv/bin",
				timeout = 30000,
			}),
		},
	})
end

return M
