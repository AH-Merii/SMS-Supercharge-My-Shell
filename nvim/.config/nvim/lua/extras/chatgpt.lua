local M = {
	"jackMort/ChatGPT.nvim",
	event = "VeryLazy",
	config = function()
		require("chatgpt").setup()
	end,
	dependencies = {
		"MunifTanjim/nui.nvim",
		"nvim-lua/plenary.nvim",
		"folke/trouble.nvim",
		"nvim-telescope/telescope.nvim",
	},
}

M.config = function()
	require("chatgpt").setup({
		api_key_cmd = "pass show openai-api/neovim-p14s",
		yank_add = "+",
		edit_with_instructions = {
			diff = false,
			keymaps = {
				close = "<C-c>",
				accept = "<C-y>",
				toggle_diff = "<C-d>",
				toggle_settings = "<C-o>",
				toggle_help = "<C-h>",
				cycle_windows = "<Tab>",
				use_output_as_input = "<C-i>",
			},
		},
		chat = {
			welcome_message = "Welcome Abed, how can I help you today?",
			loading_text = "Loading, please wait ...",
			question_sign = "", -- 🙂
			answer_sign = "ﮧ", -- 🤖
			border_left_sign = "",
			border_right_sign = "",
			max_line_length = 120,
			sessions_window = {
				active_sign = "  ",
				inactive_sign = "  ",
				current_line_sign = "",
				border = {
					style = "rounded",
					text = {
						top = " Sessions ",
					},
				},
				win_options = {
					winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
				},
			},
			keymaps = {
				close = "<C-c>",
				yank_last = "<C-y>",
				yank_last_code = "<C-k>",
				scroll_up = "<C-u>",
				scroll_down = "<C-d>",
				new_session = "<C-n>",
				cycle_windows = "<Tab>",
				cycle_modes = "<C-f>",
				next_message = "<C-j>",
				prev_message = "<C-k>",
				select_session = "<Space>",
				rename_session = "r",
				delete_session = "d",
				draft_message = "<C-r>",
				edit_message = "e",
				-- delete_message = "d",
				toggle_settings = "<C-o>",
				toggle_sessions = "<C-p>",
				toggle_help = "<C-h>",
				toggle_message_role = "<C-r>",
				toggle_system_role_open = "<C-s>",
				stop_generating = "<C-x>",
			},
		},
		popup_layout = {
			default = "center",
			center = {
				width = "80%",
				height = "80%",
			},
			right = {
				width = "30%",
				width_settings_open = "50%",
			},
		},
		popup_window = {
			border = {
				highlight = "FloatBorder",
				style = "rounded",
				text = {
					top = " ChatGPT ",
				},
			},
			win_options = {
				wrap = true,
				linebreak = true,
				foldcolumn = "1",
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
			buf_options = {
				filetype = "markdown",
			},
		},
		system_window = {
			border = {
				highlight = "FloatBorder",
				style = "rounded",
				text = {
					top = " SYSTEM ",
				},
			},
			win_options = {
				wrap = true,
				linebreak = true,
				foldcolumn = "2",
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
		},
		popup_input = {
			prompt = "  ",
			border = {
				highlight = "FloatBorder",
				style = "rounded",
				text = {
					top_align = "center",
					top = " Prompt ",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
			submit = "<C-Enter>",
			submit_n = "<Enter>",
			max_visible_lines = 20,
		},
		settings_window = {
			setting_sign = "  ",
			border = {
				style = "rounded",
				text = {
					top = " Settings ",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
		},
		help_window = {
			setting_sign = "  ",
			border = {
				style = "rounded",
				text = {
					top = " Help ",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			},
		},
		openai_params = {
			model = "gpt-4-turbo-preview",
			frequency_penalty = 0,
			presence_penalty = 0,
			temperature = 0,
			top_p = 1,
			n = 1,
		},
		openai_edit_params = {
			model = "gpt-4-turbo-preview",
			frequency_penalty = 0,
			presence_penalty = 0,
			temperature = 0,
			top_p = 1,
			n = 1,
		},
		use_openai_functions_for_edits = false,
		actions_paths = {},
		show_quickfixes_cmd = "Trouble quickfix",
		predefined_chat_gpt_prompts = "https://raw.githubusercontent.com/f/awesome-chatgpt-prompts/main/prompts.csv",
		highlights = {
			help_key = "@symbol",
			help_description = "@comment",
		},
	})

	local wk = require("which-key")

	wk.add({
		{ "<leader>C", group = "ChatGPT" }, -- Define the group for ChatGPT mappings
		{ "<leader>Cc", "<cmd>ChatGPT<CR>", desc = "ChatGPT" }, -- Keybinding for ChatGPT command
		{ "<leader>Ce", "<cmd>ChatGPTEditWithInstruction<CR>", desc = "Edit with instruction", mode = { "n", "v" } },
		{ "<leader>Cg", "<cmd>ChatGPTRun grammar_correction<CR>", desc = "Grammar Correction", mode = { "n", "v" } },
		{ "<leader>Ct", "<cmd>ChatGPTRun translate<CR>", desc = "Translate", mode = { "n", "v" } },
		{ "<leader>Ck", "<cmd>ChatGPTRun keywords<CR>", desc = "Keywords", mode = { "n", "v" } },
		{ "<leader>Cd", "<cmd>ChatGPTRun docstring<CR>", desc = "Docstring", mode = { "n", "v" } },
		{ "<leader>Ca", "<cmd>ChatGPTRun add_tests<CR>", desc = "Add Tests", mode = { "n", "v" } },
		{ "<leader>Co", "<cmd>ChatGPTRun optimize_code<CR>", desc = "Optimize Code", mode = { "n", "v" } },
		{ "<leader>Cs", "<cmd>ChatGPTRun summarize<CR>", desc = "Summarize", mode = { "n", "v" } },
		{ "<leader>Cf", "<cmd>ChatGPTRun fix_bugs<CR>", desc = "Fix Bugs", mode = { "n", "v" } },
		{ "<leader>Cx", "<cmd>ChatGPTRun explain_code<CR>", desc = "Explain Code", mode = { "n", "v" } },
		{ "<leader>Cr", "<cmd>ChatGPTRun roxygen_edit<CR>", desc = "Roxygen Edit", mode = { "n", "v" } },
		{
			"<leader>Cl",
			"<cmd>ChatGPTRun code_readability_analysis<CR>",
			desc = "Code Readability Analysis",
			mode = { "n", "v" },
		},
	})
end

return M
