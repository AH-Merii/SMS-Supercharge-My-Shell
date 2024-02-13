require("user.launch")
require("user.options")
require("user.keymaps")
require("user.wsl-clipboard")
spec("lsp.config") -- language server support configuration
spec("lsp.mason") -- manage formatters, linters, and other language servers
spec("lsp.none-ls") -- none-ls
spec("lsp.mason-null-ls") -- null-ls support to automatically download formatters/linters
spec("plugins.catppuccin") -- theme
spec("plugins.lualine") -- status
spec("plugins.luasnip") -- snippet support
spec("plugins.neotree") -- navigation bar to navigate files and directories
spec("plugins.treesitter")
spec("plugins.treesitter-textobjects")
spec("plugins.which-key") -- label shortcuts and add previews
spec("plugins.schemastore") -- json formatting support
spec("plugins.devicons") -- add devicons
spec("plugins.cmp") -- support for completion
spec("plugins.gitsigns") -- shows git changes in gutter
spec("plugins.telescope")
spec("plugins.telescope-tabs")
spec("plugins.navic") -- current file title with split support
spec("plugins.breadcrumbs") -- navigation bar top
spec("plugins.harpoon") -- save specific files for quick navigation
spec("plugins.illuminate") -- highlight text under cursor
spec("plugins.neotest") -- add neotest
spec("plugins.comment") -- add quick comment
spec("plugins.flash") -- better navigation/selection 
spec("plugins.neotab") -- better tabbing between ({[]})
spec("plugins.autopairs") -- add autopairs
spec("plugins.dashboard") -- add a startup dashboard
spec("plugins.project") -- add project manager
spec("plugins.bqf") -- better quickfix
spec("plugins.toggleterm") -- add terminals
spec("plugins.indentline") -- add indent lines
spec("plugins.surround") -- add support for surrounding text
spec("extras.dressing") -- add a dressing menu for changing colors
spec("extras.neoscroll") -- add smooth scrolling
spec("extras.navbuddy") -- add a sidebar for quick navigation of methods/classes/funcs etc..
spec("extras.ufo") -- add code folding support
spec("extras.modicator") -- change cursor color based on current vim mode
spec("extras.noice") -- add notifications and improve ui
spec("extras.sourcegraph") -- add cody and sourcegraph support
spec("extras.chatgpt") -- add chatgpt support
--language specific configurations
require("languages.python.editor")
--require("languages.lua.snippets")
require("user.lazy")
