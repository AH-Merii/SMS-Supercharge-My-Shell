local M = {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{
			"folke/neodev.nvim",
		},
	},
}

local wk = require("which-key")

local function lsp_keymaps(bufnr)
	local keymap = vim.api.nvim_buf_set_keymap
	keymap(
		bufnr,
		"n",
		"gD",
		"<cmd>lua vim.lsp.buf.declaration()<CR>",
		{ desc = "Go to Declaration", noremap = true, silent = true }
	)
	keymap(
		bufnr,
		"n",
		"gd",
		"<cmd>lua vim.lsp.buf.definition()<CR>",
		{ desc = "Go to Definition", noremap = true, silent = true }
	)
	keymap(
		bufnr,
		"n",
		"K",
		"<cmd>lua vim.lsp.buf.hover()<CR>",
		{ desc = "Hover Documentation", noremap = true, silent = true }
	)
	keymap(
		bufnr,
		"n",
		"gI",
		"<cmd>lua vim.lsp.buf.implementation()<CR>",
		{ desc = "Go to Implementation", noremap = true, silent = true }
	)
	keymap(
		bufnr,
		"n",
		"gr",
		"<cmd>lua vim.lsp.buf.references()<CR>",
		{ desc = "Go to References", noremap = true, silent = true }
	)
	keymap(
		bufnr,
		"n",
		"gl",
		"<cmd>lua vim.diagnostic.open_float()<CR>",
		{ desc = "Go to Line Diagnostics", noremap = true, silent = true }
	)
end

function M.common_capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.completion.completionItem.snippetSupport = true
	return capabilities
end

function M.on_attach(client, bufnr)
	lsp_keymaps(bufnr) -- Call the lsp_keymaps function with the buffer number
	-- Add any other on_attach logic here
end

M.toggle_inlay_hints = function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end

local function get_python_path()
	-- Use activated virtualenv if available
	local venv_path = os.getenv("VIRTUAL_ENV")
	if venv_path then
		print("Using activated virtualenv: " .. venv_path .. "/bin/python")
		return venv_path .. "/bin/python"
	end

	-- Check for a .venv directory in the project root
	local cwd = vim.fn.getcwd()
	local project_venv_path = cwd .. "/.venv/bin/python"
	if vim.fn.executable(project_venv_path) == 1 then
		print("Using project .venv: " .. project_venv_path)
		return project_venv_path
	end

	-- Fallback to system Python if no virtualenv is activated
	print("Using system Python: /usr/bin/python3")
	return "/usr/bin/python3"
end

function M.config()
	wk.add({
		{ "<leader>l", group = "LSP" }, -- Define the LSP group
		{ "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code Action", mode = { "n", "v" } }, -- Both normal and visual mode
		{
			"<leader>lf",
			"<cmd>lua vim.lsp.buf.format({async = true, filter = function(client) return client.name ~= 'typescript-tools' end})<cr>",
			desc = "Format",
			mode = "n",
		},
		{ "<leader>li", "<cmd>LspInfo<cr>", desc = "Info", mode = "n" },
		{ "<leader>lj", "<cmd>lua vim.diagnostic.goto_next()<cr>", desc = "Next Diagnostic", mode = "n" },
		{ "<leader>lh", "<cmd>lua require('lsp.config').toggle_inlay_hints()<cr>", desc = "Hints", mode = "n" },
		{ "<leader>lk", "<cmd>lua vim.diagnostic.goto_prev()<cr>", desc = "Prev Diagnostic", mode = "n" },
		{ "<leader>ll", "<cmd>lua vim.lsp.codelens.run()<cr>", desc = "CodeLens Action", mode = "n" },
		{ "<leader>lq", "<cmd>lua vim.diagnostic.setloclist()<cr>", desc = "Quickfix", mode = "n" },
		{ "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename", mode = "n" },
	})

	local lspconfig = require("lspconfig")
	local icons = require("user.icons")

	local servers = require("lsp.servers")

	local default_diagnostic_config = {
		signs = {
			active = true,
			values = {
				{ name = "DiagnosticSignError", text = icons.diagnostics.Error },
				{ name = "DiagnosticSignWarn", text = icons.diagnostics.Warning },
				{ name = "DiagnosticSignHint", text = icons.diagnostics.Hint },
				{ name = "DiagnosticSignInfo", text = icons.diagnostics.Information },
			},
		},
		virtual_text = false,
		update_in_insert = false,
		underline = true,
		severity_sort = true,
		float = {
			focusable = true,
			style = "minimal",
			border = "rounded",
			source = "always",
			header = "",
			prefix = "",
		},
	}

	vim.diagnostic.config(default_diagnostic_config)

	vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
	vim.lsp.handlers["textDocument/signatureHelp"] =
		vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
	require("lspconfig.ui.windows").default_options.border = "rounded"

	for _, server in pairs(servers) do
		local opts = {
			on_attach = M.on_attach,
			capabilities = M.common_capabilities(),
		}

		local require_ok, settings = pcall(require, "lsp.settings." .. server)
		if require_ok then
			opts = vim.tbl_deep_extend("force", settings, opts)
		end

		if server == "lua_ls" then
			require("neodev").setup({})
		elseif server == "pyright" then
			opts.settings = {
				python = {
					pythonPath = get_python_path(),
					analysis = {
						autoSearchPaths = true,
						diagnositicMode = "openFilesOnly",
						useLibraryCodeForTypes = true,
					},
				},
			}
		end

		lspconfig[server].setup(opts)
	end
end

return M
