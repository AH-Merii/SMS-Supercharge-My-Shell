return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    modes = {
      search = { enabled = true, search = { multi_window = false } },
      char = {
        -- enables cycling between next and previous
        -- if you want to override the default behaviour of f,F,t,T
        -- then we add them to the keys below
        -- I manually have custom keymaps below instead
        keys = { ";", "," },
        jump_labels = true,
      },
    },
  },
  keys = {
    {
      "f",
      mode = { "n", "x", "o" },
      function() require("flash").jump() end,
      desc = "Flash Anywhere (f)",
    },

    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    -- treesitter incremental selection
    {
      "<bs>",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter({
          actions = {
            ["+"] = "next",
            ["-"] = "prev",
            -- Adding this keymap allows us to toggle between
            -- having the char hints on and off for jumping
            -- this is useful when you simply want to use +-
            -- to incrementally increase or decrease selection
            ["%"] = function(state, _)
              -- Toggle labels
              state.opts.label.before = not state.opts.label.before
              state.opts.label.after = not state.opts.label.after

              -- refresh state
              state:update({ force = true })
            end,
          },
        })
      end,
      desc = "treesitter incremental selection",
    },
  },
}
