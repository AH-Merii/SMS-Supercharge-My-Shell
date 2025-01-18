local M = {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPost", "BufNewFile" },
	build = ":TSUpdate",
}

local languages = {
	"c",
	"python",
	"comment",
	"lua",
	"vim",
	"vimdoc",
	"query",
	"rust",
	"markdown_inline",
	"rust",
	"dockerfile",
	"diff",
	"yaml",
	"json",
	"html",
	"toml",
	"xml",
	"bash",
	"terraform",
	"typescript",
	"go",
}

local textobjects_config = {
	select = {
		enable = true,
		-- Automatically jump forward to textobj, similar to targets.vim
		lookahead = true,

		keymaps = {
			-- You can use the capture groups defined in textobjects.scm
			["af"] = { query = "@function.outer", desc = "Select outer part of a function region" },
			["if"] = { query = "@function.inner", desc = "Select inner part of a function region" },
			["ac"] = { query = "@class.outer", desc = "Select inner part of a class region" },
			["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
			-- You can also use captures from other query groups like `locals.scm`
			["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
		},

		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]]"] = { query = "@class.outer", desc = "Next class start" },
				--
				-- You can use regex matching (i.e. lua pattern) and/or pass a list in a "query" key to group multiple queires.
				["]o"] = "@loop.*",
				-- ["]o"] = { query = { "@loop.inner", "@loop.outer" } }
				--
				-- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
				-- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
				["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
				["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
			},
			-- Below will go to either the start or the end, whichever is closer.
			-- Use if you want more granular movements
			-- Make it even more gradual by adding multiple queries and regex.
			goto_next = {
				["]d"] = "@conditional.outer",
			},
			goto_previous = {
				["[d"] = "@conditional.outer",
			},
		},

		-- mapping query_strings to modes.
		selection_modes = {
			["@parameter.outer"] = "v", -- charwise
			["@function.outer"] = "V", -- linewise
			["@class.outer"] = "<c-v>", -- blockwise
		},
		include_surrounding_whitespace = true,
	},
}

local treesitter_setup = {
	ensure_installed = languages,
	auto_install = true,
	highlight = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "mi",
			node_incremental = "mi",
			node_decremental = "md",
		},
	},
	textobjects = textobjects_config,
}

function M.config()
	require("nvim-treesitter.configs").setup(treesitter_setup)
end

return M
