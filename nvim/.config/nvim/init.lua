require("user.launch")
require("user.options")
require("user.wsl-options")      -- configure wsl specific options
require("user.keymaps")
require("user.autocmds").setup() -- setup autocommands
require("user.usercmds").setup() -- setup custom user commands
spec("plugins.which-key")        -- label shortcuts and add previews
spec("lsp.config")               -- language server support configuration
spec("lsp.mason")                -- install/manage formatters, linters, and other language servers
spec("lsp.nvim-lint")            -- configure linters and languages
spec("lsp.conform")
spec("dap.nvim-dap")             -- setup debug adapter
spec("plugins.catppuccin")       -- theme
spec("plugins.lualine")          -- status
spec("plugins.luasnip")          -- snippet support
spec("plugins.treesitter")
spec("plugins.treesitter-textobjects")
spec("plugins.schemastore")   -- json formatting support
spec("plugins.devicons")      -- add devicons
spec("plugins.cmp")           -- support for completion
spec("plugins.gitsigns")      -- shows git changes in gutter
spec("plugins.telescope")
spec("plugins.navic")         -- current file title with split support
spec("plugins.breadcrumbs")   -- navigation bar top -> required for nvim navic
spec("plugins.harpoon")       -- save specific files for quick navigation
spec("plugins.illuminate")    -- highlight text under cursor
spec("plugins.neotest")       -- add neotest
spec("plugins.flash")         -- better navigation/selection
spec("plugins.dashboard")     -- add a startup dashboard
spec("plugins.bqf")           -- better quickfix
spec("plugins.toggleterm")    -- add terminals
spec("plugins.indentline")    -- add indent guide lines
spec("plugins.oil")           -- rename files and remote netrw support
spec("plugins.mini-surround") -- add support for surrounding text
spec("plugins.mini-ai")       -- better use of a (around) and i (inside)
spec("plugins.mini-pairs")    -- auto close and open pairs of brackets/quotes
spec("plugins.neoscroll")     -- animates cursor
spec("plugins.mini-comment")  -- adds automated comment support
spec("extras.dressing")       -- add a dressing menu for changing colors
spec("extras.todo-comments")  -- add highlighted to do comments
spec("extras.navbuddy")       -- add a sidebar for quick navigation of methods/classes/funcs etc..
spec("extras.modicator")      -- change cursor color based on current vim mode
spec("extras.noice")          -- add notifications and improve ui
--language specific configurations
require("languages.python.editor")
require("user.unkeymaps")
--require("languages.lua.snippets")
require("user.lazy")
--TODO: Use conform.nvim for code formatting
--TODO: find a way to toggle formatters on and off
--> github actions
--> dockerfiles
--> bash

--TODO: configure python DAP
