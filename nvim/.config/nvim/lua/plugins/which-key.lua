return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    delay = 300,
    icons = {
      breadcrumb = " ", -- symbol used in the command line area that shows your active key combo
      separator = "󱦰  ", -- symbol used between a key and it's label
      group = "", -- symbol prepended to a group
    },
    plugins = {
      spelling = {
        enabled = false,
      },
      presets = {
        operators = false,    -- adds help for operators like d, y, ...
        motions = false,      -- adds help for motions
        text_objects = false, -- help for text objects triggered after entering an operator
        windows = true,       -- default bindings on <c-w>
        nav = false,          -- misc bindings to work with windows
        z = false,            -- bindings for folds, spelling and others prefixed with z
        g = false,            -- bindings for prefixed with g
      },
    },
    win = {
      height = {
        max = math.huge,
      },
    },
    -- valid colors for reference: `azure`, `blue`, `cyan`, `green`, `grey`, `orange`, `purple`, `red`, `yellow`
    spec = {
      {
        { "<leader>l", group = "LSP", icon = { icon = "󱍔", color = "purple" } },
        { "<leader>c", group = "LSP (Trouble)", icon = { icon = "󰙎", color = "purple" } },
        { "<leader>t", group = "Test", icon = { icon = "󰙨", color = "cyan" } },
        { "<leader>D", group = "Debugger", icon = { icon = "", color = "purple" } },
        { "<leader>x", group = "Diagnostics", icon = { icon = "", color = "orange" } },
        { "<leader>W", group = "Workspace", icon = { icon = "󱃸", color = "cyan" } },

        { "g", group = "Goto", icon = { icon = "", color = "cyan" } },

      },
      {
        { "<leader>q", desc = "Quit", icon = { icon = "", color = "red" } },
        { "<leader>w", desc = "Write", icon = { icon = "", color = "green" } },
      },
      {
        -- Folds (labels only; no remaps)
        { "z", group = "Folds", icon = { icon = "", color = "yellow" } },

        { "za", desc = "Toggle fold" },
        { "zA", desc = "Toggle fold (recursive)" },

        -- Only this one needs Visual too
        { "zf", desc = "Create fold", mode = { "n", "x" }, icon = { icon = "", color = "yellow" } },

        { "zc", desc = "Close fold", icon = { icon = "", color = "orange" } },
        { "zC", desc = "Close fold (recursive)", icon = { icon = "", color = "orange" } },
        { "zo", desc = "Open fold", icon = { icon = "", color = "cyan" } },
        { "zO", desc = "Open fold (recursive)", icon = { icon = "", color = "cyan" } },
        { "zM", desc = "Close all folds", icon = { icon = "", color = "orange" } },
        { "zR", desc = "Open all folds", icon = { icon = "", color = "cyan" } },
        { "zm", desc = "More folding (increase level)", icon = { icon = "", color = "cyan" } },
        { "zr", desc = "Reduce folding (decrease level)", icon = { icon = "", color = "orange" } },
        { "zx", desc = "Recompute folds", icon = { icon = "", color = "yellow" } },
        { "zd", desc = "Delete fold under cursor", icon = { icon = "󰗨", color = "red" } },
        { "zD", desc = "Delete all manual folds", icon = { icon = "󰗩", color = "red" } },

        -- Navigation
        { "]z", desc = "fold", icon = { icon = "", color = "yellow" } },
        { "[z", desc = "fold", icon = { icon = "", color = "yellow" } },

        -- Global toggle
        { "zi", desc = "Toggle folding (foldenable)" },
      },
      {
        -- Jump groups
        { "]", group = "Jump to Next", icon = { icon = "󰒭", color = "cyan" } },
        { "[", group = "Jump to Previous", icon = { icon = "󰒮", color = "orange" } },

        -- Previous starts
        { "[f", icon = { icon = "󰊕", color = "orange" }, desc = "function" },
        { "[c", icon = { icon = "", color = "orange" }, desc = "class" },
        { "[p", icon = { icon = "", color = "orange" }, desc = "parameter" },
        { "[b", icon = { icon = "", color = "orange" }, desc = "block" },
        { "[i", icon = { icon = "󰙁", color = "orange" }, desc = "conditional" },
        { "[l", icon = { icon = "󰑖", color = "orange" }, desc = "loop" },
        { "[a", icon = { icon = "󰡱", color = "grey" }, desc = "function call" },
        { "[r", icon = { icon = "", color = "orange" }, desc = "return" },
        { "[/", icon = { icon = "󰅺", color = "grey" }, desc = "comment" },

        -- Next starts
        { "]f", icon = { icon = "󰊕", color = "purple" }, desc = " function" },
        { "]c", icon = { icon = "", color = "purple" }, desc = " class" },
        { "]p", icon = { icon = "", color = "purple" }, desc = " parameter" },
        { "]b", icon = { icon = "", color = "purple" }, desc = " block" },
        { "]i", icon = { icon = "󰙁", color = "purple" }, desc = " conditional" },
        { "]l", icon = { icon = "󰑖", color = "purple" }, desc = " loop" },
        { "]a", icon = { icon = "󰡱", color = "grey" }, desc = " function call" },
        { "]r", icon = { icon = "", color = "purple" }, desc = " return" },
        { "]/", icon = { icon = "󰅺", color = "grey" }, desc = " comment" },

        -- Previous ends
        { "[F", icon = { icon = "󰡱", color = "cyan" }, desc = "function end" },
        { "[C", icon = { icon = "󰒕", color = "cyan" }, desc = "class end" },
        { "[B", icon = { icon = "", color = "cyan" }, desc = "block end" },

        --  ends
        { "]F", icon = { icon = "󰡱", color = "cyan" }, desc = " function end" },
        { "]C", icon = { icon = "󰒕", color = "cyan" }, desc = " class end" },
        { "]B", icon = { icon = "", color = "cyan" }, desc = " block end" },

        -- Diagnostics
        { "]d", icon = { icon = "", color = "orange" }, desc = " diagnostic" },
        { "[d", icon = { icon = "", color = "orange" }, desc = "diagnostic" },

        -- Spelling
        { "]s", icon = { icon = "󰓆", color = "red" }, desc = " misspelled word" },
        { "[s", icon = { icon = "󰓆", color = "red" }, desc = "misspelled word" },

        -- Tags
        { "]t", icon = { icon = "", color = "yellow" }, desc = " tag" },
        { "[t", icon = { icon = "", color = "yellow" }, desc = "tag" },

        -- Folds
        { "]z", icon = { icon = "", color = "yellow" }, desc = " fold end" },
        { "[z", icon = { icon = "", color = "yellow" }, desc = "fold start" },

        -- Location list
        { "]l", icon = { icon = "", color = "yellow" }, desc = " loclist item" },
        { "[l", icon = { icon = "", color = "yellow" }, desc = "loclist item" },

        -- Quickfix list
        { "]q", icon = { icon = "", color = "yellow" }, desc = " quickfix item" },
        { "[q", icon = { icon = "", color = "yellow" }, desc = "quickfix item" },

        -- Git hunks
        { "]g", icon = { icon = "", color = "green" }, desc = " git hunk" },
        { "[g", icon = { icon = "", color = "green" }, desc = "git hunk" },

        { "[ ", desc = "Add Space Above", icon = { icon = "󰞙", color = "grey" } },
        { "] ", desc = "Add Space Below", icon = { icon = "󰞖", color = "grey" } },
      },

      -- hide the following keymaps
      {
        -- jump forward
        { "]L",     hidden = true },
        { "]T",     hidden = true },
        { "]D",     hidden = true },
        { "]A",     hidden = true },
        { "]Q",     hidden = true },
        { "]<C-T>", hidden = true },
        { "]<C-Q>", hidden = true },
        { "]<C-T>", hidden = true },
        { "]<C-L>", hidden = true },
        { "]%",     hidden = true },

        -- jump backward
        { "[L",     hidden = true },
        { "[T",     hidden = true },
        { "[D",     hidden = true },
        { "[A",     hidden = true },
        { "[Q",     hidden = true },
        { "[<C-T>", hidden = true },
        { "[<C-Q>", hidden = true },
        { "[<C-T>", hidden = true },
        { "[<C-L>", hidden = true },
        { "[%",     hidden = true },
      },
    }
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
