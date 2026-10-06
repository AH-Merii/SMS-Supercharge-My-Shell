-- the icon only where a buffer map shadows the global default, as the treesitter moves do on ]b, ]a and ]l
local function on_buffer_map(icon)
  -- in the popup's mode: m.mode is the spec's whole mode list
  return function(m) return vim.fn.maparg(m.lhs, require("which-key.util").mapmode(), false, true).buffer == 1 and icon or nil end
end

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
        operators = false, -- adds help for operators like d, y, ...
        motions = false, -- adds help for motions
        text_objects = false, -- help for text objects triggered after entering an operator
        windows = true, -- default bindings on <c-w>
        nav = false, -- misc bindings to work with windows
        z = false, -- bindings for folds, spelling and others prefixed with z
        g = false, -- bindings for prefixed with g
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
        { "<leader>l", group = "LSP", mode = { "n", "x" }, icon = { icon = "󱍔", color = "purple" } },
        { "<leader>c", group = "LSP (Trouble)", icon = { icon = "󰙎", color = "purple" } },
        { "<leader>x", group = "Diagnostics", icon = { icon = "", color = "orange" } },

        { "g", group = "Goto", mode = { "n", "x" }, icon = { icon = "", color = "cyan" } },
        { "s", group = "Surround", mode = "x" },
      },
      {
        mode = { "x", "o" },
        { "a", group = "Around" },
        { "i", group = "Inside" },
      },
      {
        { "<leader>q", desc = "Quit", icon = { icon = "", color = "red" } },
        { "<leader>w", desc = "Write", icon = { icon = "", color = "green" } },
        { "<leader>p", mode = { "n", "x" }, icon = { icon = "", color = "cyan" }, real = true },
        { "<leader>v", icon = { icon = "󰩭", color = "cyan" }, real = true },
      },
      {
        -- Folds (labels only; no remaps)
        { "z", group = "Folds", mode = { "n", "x" }, icon = { icon = "", color = "yellow" } },

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

        -- Global toggle
        { "zi", desc = "Toggle folding (foldenable)" },
      },
      {
        mode = { "n", "x", "o" }, -- real = true keeps a key to the modes it is mapped in
        -- Jump groups
        { "]", group = "Jump to Next", icon = { icon = "󰒭", color = "cyan" } },
        { "[", group = "Jump to Previous", icon = { icon = "󰒮", color = "orange" } },

        -- Previous starts
        { "[f", icon = { icon = "󰊕", color = "orange" }, real = true },
        { "[c", icon = { icon = "", color = "orange" }, real = true },
        { "[p", icon = { icon = "", color = "orange" }, real = true },
        { "[i", icon = { icon = "󰙁", color = "orange" }, real = true },
        { "[r", icon = { icon = "󰌑", color = "orange" }, real = true },
        { "[b", icon = on_buffer_map({ icon = "󰅩", color = "orange" }), real = true },
        { "[a", icon = on_buffer_map({ icon = "󰅪", color = "orange" }), real = true },
        { "[l", icon = on_buffer_map({ icon = "", color = "orange" }), real = true },
        { "[/", icon = { icon = "󰅺", color = "grey" }, real = true },

        -- Next starts
        { "]f", icon = { icon = "󰊕", color = "purple" }, real = true },
        { "]c", icon = { icon = "", color = "purple" }, real = true },
        { "]p", icon = { icon = "", color = "purple" }, real = true },
        { "]i", icon = { icon = "󰙁", color = "purple" }, real = true },
        { "]r", icon = { icon = "󰌑", color = "purple" }, real = true },
        { "]b", icon = on_buffer_map({ icon = "󰅩", color = "purple" }), real = true },
        { "]a", icon = on_buffer_map({ icon = "󰅪", color = "purple" }), real = true },
        { "]l", icon = on_buffer_map({ icon = "", color = "purple" }), real = true },
        { "]/", icon = { icon = "󰅺", color = "grey" }, real = true },

        -- Previous ends
        { "[F", icon = { icon = "󰡱", color = "cyan" }, real = true },
        { "[C", icon = { icon = "󰒕", color = "cyan" }, real = true },
        { "[B", icon = { icon = "", color = "cyan" }, real = true },

        --  ends
        { "]F", icon = { icon = "󰡱", color = "cyan" }, real = true },
        { "]C", icon = { icon = "󰒕", color = "cyan" }, real = true },
        { "]B", icon = { icon = "", color = "cyan" }, real = true },

        -- Filetype plugin motions, labelled in after/ftplugin
        { "[m", icon = { icon = "", color = "orange" }, real = true },
        { "]m", icon = { icon = "", color = "purple" }, real = true },
        { "[M", icon = { icon = "", color = "cyan" }, real = true },
        { "]M", icon = { icon = "", color = "cyan" }, real = true },
        { "[]", icon = { icon = "", color = "cyan" }, real = true },
        { "][", icon = { icon = "", color = "cyan" }, real = true },
        -- Snacks words references, or the filetype plugin's sections
        { "]]", icon = { icon = "", color = "grey" }, real = true },
        { "[[", icon = { icon = "", color = "grey" }, real = true },

        -- Spelling
        { "]s", icon = { icon = "󰓆", color = "red" }, desc = " misspelled word" },
        { "[s", icon = { icon = "󰓆", color = "red" }, desc = "misspelled word" },

        -- Folds
        { "]z", icon = { icon = "", color = "yellow" }, desc = " fold end" },
        { "[z", icon = { icon = "", color = "yellow" }, desc = "fold start" },

        -- Git hunks
        { "]g", icon = { icon = "", color = "green" }, desc = " git hunk", real = true },
        { "[g", icon = { icon = "", color = "green" }, desc = "git hunk", real = true },

        -- built-ins that do nothing in visual and operator-pending mode
        {
          mode = "n",
          -- Diagnostics
          { "]d", icon = { icon = "", color = "orange" }, desc = " diagnostic" },
          { "[d", icon = { icon = "", color = "orange" }, desc = "diagnostic" },

          -- Tags
          { "]t", icon = { icon = "", color = "yellow" }, desc = " tag" },
          { "[t", icon = { icon = "", color = "yellow" }, desc = "tag" },

          -- Quickfix list
          { "]q", icon = { icon = "", color = "yellow" }, desc = " quickfix item" },
          { "[q", icon = { icon = "", color = "yellow" }, desc = "quickfix item" },

          { "[ ", desc = "Add Space Above", icon = { icon = "󰞙", color = "grey" } },
          { "] ", desc = "Add Space Below", icon = { icon = "󰞖", color = "grey" } },
        },
      },

      -- hide the following keymaps
      {
        -- jump forward
        { "]L", hidden = true },
        { "]T", hidden = true },
        { "]D", hidden = true },
        { "]A", hidden = true },
        { "]Q", hidden = true },
        { "]<C-T>", hidden = true },
        { "]<C-Q>", hidden = true },
        { "]<C-T>", hidden = true },
        { "]<C-L>", hidden = true },
        { "]%", hidden = true },

        -- jump backward
        { "[L", hidden = true },
        { "[T", hidden = true },
        { "[D", hidden = true },
        { "[A", hidden = true },
        { "[Q", hidden = true },
        { "[<C-T>", hidden = true },
        { "[<C-Q>", hidden = true },
        { "[<C-T>", hidden = true },
        { "[<C-L>", hidden = true },
        { "[%", hidden = true },
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  },
}
