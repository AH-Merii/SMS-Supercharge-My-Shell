return {
  {
    "lewis6991/gitsigns.nvim",
    lazy = false,
    config = function()
      local gs = require("gitsigns")
      local gsc = require("gitsigns.config")
      local signs_column = Snacks.toggle.new({
        name = "Git Signs Column",
        get = function() return gsc.config.signcolumn end,
        set = function(state) gs.toggle_signs(state) end,
      })

      local hunk_keys = {
        { "[g", function() require("gitsigns").nav_hunk("prev", { navigation_message = false }) end, desc = "Prev Hunk" },
        { "]g", function() require("gitsigns").nav_hunk("next", { navigation_message = false }) end, desc = "Next Hunk" },
        { "<leader>gb", function() require("gitsigns").blame_line() end, desc = "Blame" },
        { "<leader>gd", function() require("gitsigns").preview_hunk() end, desc = "Diff (Preview)" },
        { "<leader>Gr", function() require("gitsigns").reset_hunk() end, desc = "Reset Hunk" },
        { "<leader>GR", function() require("gitsigns").reset_buffer() end, desc = "Reset Buffer" },
        { "<leader>Gs", function() require("gitsigns").stage_hunk() end, desc = "Stage Hunk" },
        { "<leader>Gu", function() require("gitsigns").stage_hunk() end, desc = "Unstage Hunk" },
        { "<leader>Gd", function() vim.cmd("Gitsigns diffthis HEAD") end, desc = "Diff (vs HEAD)" },
      }

      gs.setup({
        signs = {
          add = { text = "" }, -- added line
          change = { text = "" }, -- modified line
          delete = { text = "" }, -- deleted line
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
          follow_files = true,
        },
        attach_to_untracked = true,
        current_line_blame = false, -- toggleable via :Gitsigns toggle_current_line_blame
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
        on_attach = function(buf)
          for _, key in ipairs(hunk_keys) do
            vim.keymap.set("n", key[1], key[2], { buf = buf, desc = key.desc })
          end
          signs_column:map("<leader>TG", { buf = buf })
        end,
      })

      -- gitsigns clears the status dict when it detaches, e.g. after the file is renamed out of the repo
      vim.api.nvim_create_autocmd("User", {
        pattern = "GitSignsUpdate",
        group = vim.api.nvim_create_augroup("GitsignsKeys", { clear = true }),
        callback = function(ev)
          local buf = ev.data and ev.data.buffer
          if buf and vim.api.nvim_buf_is_valid(buf) and vim.b[buf].gitsigns_status_dict == nil then
            for _, key in ipairs(hunk_keys) do
              pcall(vim.keymap.del, "n", key[1], { buf = buf })
            end
            pcall(vim.keymap.del, "n", "<leader>TG", { buf = buf })
          end
        end,
      })

      -- Optional which-key sugar (just like in Snacks)
      local ok, wk = pcall(require, "which-key")
      if ok then
        wk.add({
          -- high level group for Git actions (capital G to mirror your <leader>T etc.)
          { "<leader>G", group = "Git (Actions)", icon = { icon = "", color = "cyan" } },
          { "<leader>g", group = "Git (Inspect)", icon = { icon = "", color = "cyan" } },

          -- actions
          { "<leader>Gs", icon = { icon = "", color = "green" }, real = true }, -- stage hunk
          { "<leader>Gu", icon = { icon = "", color = "yellow" }, real = true }, -- unstage hunk
          { "<leader>Gr", icon = { icon = "󰁯", color = "orange" }, real = true }, -- reset hunk
          { "<leader>GR", icon = { icon = "󱄍", color = "red" }, real = true }, -- reset buffer
          { "<leader>Gd", icon = { icon = "", color = "purple" }, real = true }, -- diff (HEAD)

          { "<leader>gb", icon = { icon = "󰩔", color = "yellow" }, real = true }, -- blame
          { "<leader>gd", icon = { icon = "󰦓", color = "cyan" }, real = true }, -- diff preview
        })
      else
        vim.notify("which-key.nvim not found. Install it for Git icons/groups.", vim.log.levels.WARN, { title = "gitsigns.nvim" })
      end
    end,
  },

  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
  },

  -- not git, but lives in the same mental drawer: "history / timeline"
  {
    "mbbill/undotree",
    keys = {
      { "<leader>GU", ":UndotreeToggle<CR>", desc = "Toggle UndoTree" },
    },
  },
}
