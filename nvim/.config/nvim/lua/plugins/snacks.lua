return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = { enabled = false },
    indent = { enabled = true },
    input = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
  keys = {
    --   File Pickers: Access files, buffers, and projects quickly
    { "<leader>ff", function() Snacks.picker.smart() end,                 desc = "Find Files" },
    { "<leader>fb", function() Snacks.picker.buffers() end,               desc = "Buffers" },
    { "<leader>fp", function() Snacks.picker.projects() end,              desc = "Projects" },
    { "<leader>fr", function() Snacks.picker.recent() end,                desc = "Recent Files" },

    --   Git Tools: Interact with branches, logs, and diffs
    { "<leader>gB", function() Snacks.picker.git_branches() end,          desc = "Branches" },
    { "<leader>gl", function() Snacks.picker.git_log() end,               desc = "Log" },
    { "<leader>gL", function() Snacks.picker.git_log_line() end,          desc = "Log (Line)" },
    { "<leader>gs", function() Snacks.picker.git_status() end,            desc = "Status" },
    { "<leader>gS", function() Snacks.picker.git_stash() end,             desc = "Stashes" },
    { "<leader>gD", function() Snacks.picker.git_diff() end,              desc = "Diff (Hunks)" },
    { "<leader>gf", function() Snacks.picker.git_log_file() end,          desc = "Log (File)" },

    -- 󰞷  Search: Grep and search across files and buffers
    { "<leader>/",  function() Snacks.picker.grep() end,                  desc = "Grep (Project)" },
    { "<leader>sB", function() Snacks.picker.grep_buffers() end,          desc = "Grep (Open Buffers)" },
    { "<leader>sw", function() Snacks.picker.grep_word() end,             desc = "Grep (Word/Selection)",  mode = { "n", "x" } },
    { "<leader>sb", function() Snacks.picker.lines() end,                 desc = "Grep (Buffer Lines)" },

    -- 󱦞 Search: System & Editor: Inspect commands, diagnostics, and help
    { '<leader>s"', function() Snacks.picker.registers() end,             desc = "Registers" },
    { "<leader>sa", function() Snacks.picker.autocmds() end,              desc = "Autocommands" },
    { "<leader>s:", function() Snacks.picker.command_history() end,       desc = "Command History" },
    { "<leader>sc", function() Snacks.picker.commands() end,              desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics_buffer() end,    desc = "Diagnostics (Buffer)" },
    { "<leader>sD", function() Snacks.picker.diagnostics() end,           desc = "Diagnostics (Workspace)" },
    { "<leader>sh", function() Snacks.picker.help() end,                  desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end,            desc = "Highlight Groups" },
    { "<leader>si", function() Snacks.picker.icons() end,                 desc = "Icons" },
    { "<leader>sj", function() Snacks.picker.jumps() end,                 desc = "Jump List" },
    { "<leader>sk", function() Snacks.picker.keymaps() end,               desc = "Keymaps" },
    { "<leader>sl", function() Snacks.picker.loclist() end,               desc = "Location List" },
    { "<leader>sm", function() Snacks.picker.marks() end,                 desc = "Marks" },
    { "<leader>sM", function() Snacks.picker.man() end,                   desc = "Man Pages" },
    { "<leader>sp", function() Snacks.picker.lazy() end,                  desc = "Plugins (Lazy)" },
    { "<leader>sq", function() Snacks.picker.qflist() end,                desc = "Quickfix List" },
    { "<leader>sR", function() Snacks.picker.resume() end,                desc = "Resume Last Search" },
    { "<leader>su", function() Snacks.picker.undo() end,                  desc = "Undo History" },
    { "<leader>sC", function() Snacks.picker.colorschemes() end,          desc = "Colorschemes" },
    { "<leader>ss", function() Snacks.scratch.select() end,               desc = "Scratch Buffers" },


    -- 󰒕  LSP: Language features (symbols, definitions, references)
    { "gD",         function() Snacks.picker.lsp_declarations() end,      desc = "Declaration" },
    { "gd",         function() Snacks.picker.lsp_definitions() end,       desc = "Definition" },
    { "gI",         function() Snacks.picker.lsp_implementations() end,   desc = "Implementations" },
    { "<leader>ss", function() snacks.picker.lsp_workspace_symbols() end, desc = "workspace symbols" },
    { "gr",         function() Snacks.picker.lsp_references() end,        desc = "References",             nowait = true },
    -- { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
    { "gt",         function() Snacks.picker.lsp_type_definitions() end,  desc = "Type Definition" },
    { "gCi",        function() Snacks.picker.lsp_incoming_calls() end,    desc = "Incoming Calls" },
    { "gCo",        function() Snacks.picker.lsp_outgoing_calls() end,    desc = "Outgoing Calls" },

    -- Misc
    { "<leader>n",  function() Snacks.picker.notifications() end,         desc = "Notification History" },
    { "<C-W>z",     function() Snacks.zen() end,                          desc = "Toggle Zen Mode" },
    { "<C-W>Z",     function() Snacks.zen.zoom() end,                     desc = "Toggle Zoom" },
    { "<leader>.",  function() Snacks.scratch() end,                      desc = "Toggle Scratch Buffer" },
    { "<leader>lR", function() Snacks.rename.rename_file() end,           desc = "Rename File" },
    { "<leader>GB", function() Snacks.gitbrowse() end,                    desc = "Open in Git Browser" },
    { "]]",         function() Snacks.words.jump(vim.v.count1) end,       desc = "Reference (word)" },
    { "[[",         function() Snacks.words.jump(-vim.v.count1) end,      desc = "Reference (word)" },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    -- Try to register icons with which-key
    -- Below adds appropriate icons to the existing keymaps defined above
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        -- Groups
        { "<leader>f", group = "Find", icon = { icon = "󰈞", color = "blue" } },
        { "<leader>s", group = "Search", icon = { icon = "󰞷", color = "cyan" } },
        { "<leader>G", group = "Git (Actions)", icon = { icon = "", color = "cyan" } },
        { "<leader>g", group = "Git (Inspect)", icon = { icon = "", color = "cyan" } },
        { "<leader>T", group = "Toggle Features", icon = { icon = "", color = "yellow" } },

        -- find
        { "<leader>ff", icon = { icon = "󰈞", color = "blue" } },
        { "<leader>fb", icon = { icon = "", color = "grey" } },
        { "<leader>fp", icon = { icon = "", color = "grey" } },
        { "<leader>fr", icon = { icon = "", color = "yellow" } },

        -- git
        { "<leader>gB", icon = { icon = "", color = "grey" } },
        { "<leader>gl", icon = { icon = "", color = "orange" } },
        { "<leader>gL", icon = { icon = "", color = "yellow" } },
        { "<leader>gf", icon = { icon = "", color = "blue" } },
        { "<leader>gs", icon = { icon = "󰊢", color = "cyan" } },
        { "<leader>gS", icon = { icon = "󰀼", color = "grey" } },
        { "<leader>gD", icon = { icon = "", color = "cyan" } },

        -- Grep-in
        { "<leader>/", icon = { icon = "󰞷", color = "cyan" } },
        { "<leader>sB", icon = { icon = "󰱼", color = "cyan" } },
        { "<leader>sw", icon = { icon = "", color = "cyan" } },
        { "<leader>sb", icon = { icon = "", color = "cyan" } },

        -- Search
        { '<leader>s"', icon = { icon = "󰌓", color = "grey" } },
        { "<leader>sa", icon = { icon = "󰆍", color = "grey" } },
        { "<leader>s:", icon = { icon = "", color = "yellow" } },
        { "<leader>sc", icon = { icon = "󰘳", color = "grey" } },
        { "<leader>sd", icon = { icon = "", color = "orange" } },
        { "<leader>sD", icon = { icon = "", color = "orange" } },
        { "<leader>sh", icon = { icon = "󰘥", color = "grey" } },
        { "<leader>sH", icon = { icon = "", color = "yellow" } },
        { "<leader>si", icon = { icon = "", color = "grey" } },
        { "<leader>sj", icon = { icon = "󱞰", color = "yellow" } },
        { "<leader>sk", icon = { icon = "󰌌", color = "cyan" } },
        { "<leader>sl", icon = { icon = "", color = "yellow" } },
        { "<leader>sm", icon = { icon = "󰈿", color = "red" } },
        { "<leader>sM", icon = { icon = "󰮳", color = "grey" } },
        { "<leader>sp", icon = { icon = "󰏖", color = "purple" } },
        { "<leader>sq", icon = { icon = "", color = "yellow" } },
        { "<leader>sR", icon = { icon = "󰑖", color = "orange" } },
        { "<leader>su", icon = { icon = "󰕍", color = "yellow" } },
        { "<leader>sC", icon = { icon = "󰏘", color = "purple" } },
        --{ "<leader>ss", icon = { icon = "󰠱", color = "grey" } },
        { "<leader>ss", icon = { icon = "󰎕", color = "grey" } },
        { "<leader>sS", icon = { icon = "󰒕", color = "grey" } },

        -- LSP
        { "gd", icon = { icon = "󰊕", color = "purple" } },
        { "gD", icon = { icon = "󱈸", color = "purple" } },
        { "gr", icon = { icon = "", color = "purple" } },
        { "gI", icon = { icon = "󰡱", color = "purple" } },
        { "gt", icon = { icon = "", color = "purple" } },

        { "gC", group = "calls", icon = { icon = "󰃻", color = "yellow" } },
        { "gCi", icon = { icon = "󰃺", color = "cyan" } },
        { "gCo", icon = { icon = "󰃷", color = "orange" } },

        -- Misc
        { "<leader>n", icon = { icon = "󰂚", color = "yellow" } },
        { "<C-W>z", icon = { icon = "󰫢", color = "yellow" } },
        { "<C-W>Z", icon = { icon = "󰘖", color = "yellow" } },
        { "<leader>.", icon = { icon = "󰎕", color = "grey" } },
        { "<leader>lR", icon = { icon = "󰑕", color = "green" } },
        { "<leader>GB", icon = { icon = "󰖟", color = "grey" } },
        { "]]", icon = { icon = "", color = "grey" } },
        { "[[", icon = { icon = "", color = "grey" } },

      })
    else
      vim.notify(
        "which-key.nvim not found. Install it for enhanced keymap icons and descriptions.",
        vim.log.levels.WARN,
        { title = "Snacks Config" }
      )
    end
  end,
  init = function()
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup
    local user_group = augroup("SnacksUserAutocmds", { clear = true })

    autocmd("User", {
      group = user_group,
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end

        vim._print = function(_, ...)
          dd(...)
        end

        -- Define a helper to safely add gitsigns toggle
        local function setup_gitsigns_toggle()
          local ok, gs = pcall(require, "gitsigns")
          local okc, gsc = pcall(require, "gitsigns.config")
          if ok and okc then
            Snacks.toggle.new({
              name = "Git Signs Column",
              get = function() return gsc.config.signcolumn end,
              set = function(state)
                gs.toggle_signs(state)
              end,
            }):map("<leader>TG")
          else
            vim.notify(
              "gitsigns.nvim not found. Skipping gitsigns column toggle option.",
              vim.log.levels.WARN,
              { title = "Snacks Config" }
            )
          end
        end

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>Ts")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>Tw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>TL")
        Snacks.toggle.diagnostics():map("<leader>Td")
        Snacks.toggle.line_number():map("<leader>Tl")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map(
          "<leader>Tc")
        Snacks.toggle.treesitter():map("<leader>TT")
        Snacks.toggle.inlay_hints():map("<leader>Th")
        Snacks.toggle.indent():map("<leader>Tg")
        Snacks.toggle.dim():map("<leader>TD")
        Snacks.toggle.option("list", { name = "Show Hidden Chars" }):map("TH")

        setup_gitsigns_toggle()
      end,
    })
  end,
}
