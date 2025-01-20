local M = {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		-- general tests
		"vim-test/vim-test",
		"nvim-neotest/neotest-vim-test",
		-- language specific tests
		"marilari88/neotest-vitest",
		"nvim-neotest/neotest-python",
		"nvim-neotest/neotest-plenary",
		"nvim-neotest/nvim-nio",
		"rouge8/neotest-rust",
		"lawrence-laz/neotest-zig",
		"rcasia/neotest-bash",
	},
}

function M.config()
	local wk = require("which-key")
  wk.add({
    { "<leader>tt", "<cmd>lua require('neotest').run.run()<cr>", desc = "Test Nearest" }, -- Run the nearest test
    { "<leader>tf", "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", desc = "Test File" }, -- Run all tests in the current file
    { "<leader>td", "<cmd>lua require('neotest').run.run({strategy = 'dap'})<cr>", desc = "Debug Test" }, -- Debug the nearest test using DAP
    { "<leader>ts", "<cmd>lua require('neotest').run.stop()<cr>", desc = "Test Stop" }, -- Stop the running test
    { "<leader>ta", "<cmd>lua require('neotest').run.attach()<cr>", desc = "Attach Test" }, -- Attach to a running test
  })

	---@diagnostic disable: missing-fields
	require("neotest").setup({
		adapters = {
			require("neotest-python")({
				dap = { justMyCode = false },
			}),
			require("neotest-vitest"),
			require("neotest-zig"),
			require("neotest-vim-test")({
				ignore_file_types = { "python", "vim", "lua", "javascript", "typescript" },
			}),
		},
	})
end

return M
