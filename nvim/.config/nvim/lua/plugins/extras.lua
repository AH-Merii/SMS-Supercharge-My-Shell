return {

  -- Neovim notifications and LSP progress messages
  {
    "j-hui/fidget.nvim",
  },

  -- Heuristically set buffer options
  -- {
  -- 	"tpope/vim-sleuth",
  -- },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {},
  },

  {
    "echasnovski/mini.nvim",
    event = "VeryLazy",
    dependencies = {
      { "echasnovski/mini.icons", lazy = true, opts = {} },
    },
    config = function() require("mini.surround").setup() end,
  },

  {
    "nvim-tree/nvim-web-devicons",
  },

  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    init = function()
      -- Reusable function to register keymaps in different contexts
      local function set_keymaps()
        vim.keymap.set({ "n", "t" }, "<C-h>", "<cmd>TmuxNavigateLeft<cr>")
        vim.keymap.set({ "n", "t" }, "<C-j>", "<cmd>TmuxNavigateDown<cr>")
        vim.keymap.set({ "n", "t" }, "<C-k>", "<cmd>TmuxNavigateUp<cr>")
        vim.keymap.set({ "n", "t" }, "<C-l>", "<cmd>TmuxNavigateRight<cr>")
      end

      -- Register once globally
      set_keymaps()

      -- Re-register for terminal buffers to prevent literal command injection
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = set_keymaps,
      })
    end,
  },

  -- Better folding
  {
    "chrisgrieser/nvim-origami",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPre", "BufWinEnter" },
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99

      vim.opt.fillchars = {
        fold = " ",
        foldopen = "",
        foldclose = "",
        foldsep = " ",
      }
    end,
    opts = {
      foldtext = {
        lineCount = {
          template = "󰘖 %d", -- `%d` is replaced with the number of folded lines
        },
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
  {
    "brenoprata10/nvim-highlight-colors",
    opts = {
      render = "virtual",
      virtual_symbol = "",
      ---Set virtual symbol suffix (defaults to '')
      virtual_symbol_prefix = " ",

      ---Set virtual symbol suffix (defaults to ' ')
      virtual_symbol_suffix = "",
      ---Set virtual symbol position()
      ---@usage 'inline'|'eol'|'eow'
      ---inline mimics VS Code style
      ---eol stands for `end of column` - Recommended to set `virtual_symbol_suffix = ''` when used.
      ---eow stands for `end of word` - Recommended to set `virtual_symbol_prefix = ' ' and virtual_symbol_suffix = ''` when used.
      virtual_symbol_position = "eol",
    },
  },
}
