return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    delay = 300,
    icons = {
      breadcrumb = " ", -- symbol used in the command line area that shows your active key combo
      separator = "󱦰  ", -- symbol used between a key and it's label
      group = "󰪴 ", -- symbol prepended to a group
    },
    plugins = {
      spelling = {
        enabled = true,
      },
    },
    win = {
      height = {
        max = math.huge,
      },
    },
    spec = {
      {
        mode = { "n", "v" },
        { "<leader>f", group = "Find", icon = "󰈞" },
        { "<leader>G", group = "Git", icon = "" },
        { "<leader>g", group = "Gitsigns", icon = "" },
        { "<leader>l", group = "LSP", icon = "󱍔" },
        { "<leader>c", group = "LSP (Trouble)" },
        { "<leader>t", group = "Test", icon = "󰙨" },
        { "<leader>D", group = "Debugger", icon = " " },
        { "<leader>s", group = "Search", icon = "󰞷" },
        { "<leader>x", group = "Diagnostics", icon = "" },
        { "<leader>u", group = "Toggle Features", icon = "󰔡" },
        { "<leader>W", group = "Workspace", icon = "󱃸" },
        { "[", group = "prev", icon = "" },
        { "]", group = "next", icon = "" },
        { "g", group = "goto", icon = "" },
        { "<leader>q", desc = "Quit", icon = "" },
        { "<leader>w", desc = "Write", icon = "" },
        { "<leader>S", icon = "" },
        { "<leader>.", icon = "" },
        { "<leader>z", icon = "" },
        { "<leader>Z", icon = "󰘖" },
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Local Keymaps (which-key)",
    },
  }
}
