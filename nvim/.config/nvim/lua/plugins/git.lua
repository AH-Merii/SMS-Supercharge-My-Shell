return {
  {
    "lewis6991/gitsigns.nvim",
    lazy = false,
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "" }, -- `nf-oct-plus` from Octicons
          change = { text = "" }, -- `nf-oct-sync` from Octicons
          delete = { text = "" }, -- `nf-oct-trashcan` from Octicons
          topdelete = { text = "" },
          changedelete = { text = "󰦒" },
          untracked = { text = "" },
        },
        signs_staged = {
          add = { text = "󰐖" },
          change = { text = "" },
          delete = { text = "󰍵" },
          topdelete = { text = "󰍵" },
          changedelete = { text = "󰦓" },
          untracked = { text = "󰄲" },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
          interval = 1000,
          follow_files = true,
        },
        attach_to_untracked = true,
        current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
          delay = 1000,
          ignore_whitespace = false,
        },
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
        sign_priority = 6,
        status_formatter = nil,
        update_debounce = 200,
        max_file_length = 40000,
        preview_config = {
          border = "rounded",
          style = "minimal",
          relative = "cursor",
          row = 0,
          col = 1,
        },
        -- yadm = { enable = false },
      })
    end,
    keys = {
      {
        "[g",
        function()
          require("gitsigns").prev_hunk({ navigation_message = false })
        end,
        desc = "Prev Hunk",
      },
      {
        "<leader>gb",
        function()
          require("gitsigns").blame_line()
        end,
        desc = "Blame",
      },
      {
        "<leader>gd",
        function()
          require("gitsigns").preview_hunk()
        end,
        desc = "Diff (Preview)",
      },
      {
        "<leader>Gr",
        function()
          require("gitsigns").reset_hunk()
        end,
        desc = "Reset Hunk",
      },
      {
        "<leader>GR",
        function()
          require("gitsigns").reset_buffer()
        end,
        desc = "Reset Buffer",
      },
      {
        "]g",
        function()
          require("gitsigns").next_hunk({ navigation_message = false })
        end,
        desc = "Next Hunk",
      },
      {
        "<leader>Gs",
        function()
          require("gitsigns").stage_hunk()
        end,
        desc = "Stage Hunk",
      },
      {
        "<leader>Gu",
        function()
          require("gitsigns").undo_stage_hunk()
        end,
        desc = "Undo Stage Hunk",
      },
      {
        "<leader>Gd",
        function()
          vim.cmd("Gitsigns diffthis HEAD")
        end,
        desc = "Diff",
      },
    },
  },
  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
  },

  -- not git, but it's okay
  {
    "mbbill/undotree",
    keys = {
      {
        "<leader>GU",
        ":UndotreeToggle<CR>",
        desc = "Toggle UndoTree",
      },
    },
  },
}
