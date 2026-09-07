return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    -- Alternative theme. Switch with `:colorscheme catppuccin-frappe` (or -latte/-macchiato/-mocha):
    -- Neovim >= 0.12 bundles its own `colors/catppuccin.vim`, so the bare name resolves to that
    -- file and never loads this plugin; the flavour names are only provided here.
    lazy = true,
    config = function()
      require("catppuccin").setup({
        background = {
          light = "latte",
          dark = "frappe",
        },
        auto_integrations = true, -- automatically detect installed plugins from lazy
        transparent_background = true,
        float = {
          transparent = true, -- enable transparent floating windows
          solid = false, -- use solid styling for floating windows, see |winborder|
        },
        integrations = {
          barbecue = {
            dim_dirname = true,
            bold_basename = true,
            dim_context = false,
            alt_background = false,
          },
          blink_cmp = {
            style = "bordered",
          },
          gitsigns = true,
          hop = true,
          illuminate = { enabled = true },
          native_lsp = { enabled = true },
          semantic_tokens = true,
          treesitter = true,
          treesitter_context = true,
          vimwiki = true,
          which_key = true,
          aerial = true,
          fidget = true,
          mason = true,
          neotest = true,
          dap_ui = true,
          noice = true,
          snacks = {
            enabled = true,
          },
          lsp_trouble = true,
        },

        highlight_overrides = {
          all = function(colors)
            return {
              FloatBorder = { fg = colors.text, bg = "none" },
              -- popup menu
              Pmenu = { bg = "none" },
              NormalFloat = { bg = "none" },
              CursorLineFold = { fg = colors.pink, style = { "bold" } },
              CursorLineNr = { fg = colors.pink, style = { "bold" } },
              CursorLineSign = { fg = colors.pink, style = { "bold" } },

              LineNr = { fg = colors.overlay0 },

              GitSignsChange = { fg = colors.peach },

              YankHighlight = { bg = colors.surface2 },

              IblIndent = { fg = colors.surface0 },
              IblScope = { fg = colors.overlay0 },

              FidgetTask = { fg = colors.subtext1 },
              FidgetTitle = { fg = colors.peach },

              -- Word under cursor / LSP reference style (below makes it bold, when cursor is on word)
              LspReferenceText = { bg = "none", style = { "bold" } },
              LspReferenceRead = { bg = "none", style = { "bold" } },
              LspReferenceWrite = { bg = "none", style = { "bold" } },

              IlluminatedWordText = { bg = "none", style = { "bold" } },
              IlluminatedWordRead = { bg = "none", style = { "bold" } },
              IlluminatedWordWrite = { bg = "none", style = { "bold" } },

              -- -------------------------
              -- Syntax / Treesitter layer
              -- -------------------------

              Boolean = { fg = colors.mauve },
              Number = { fg = colors.mauve },
              Float = { fg = colors.mauve },

              PreProc = { fg = colors.mauve },
              PreCondit = { fg = colors.mauve },
              Include = { fg = colors.mauve },
              Define = { fg = colors.mauve },

              Conditional = { fg = colors.red },
              Repeat = { fg = colors.red },
              Keyword = { fg = colors.red },
              Typedef = { fg = colors.red },
              Exception = { fg = colors.red },
              Statement = { fg = colors.red },

              Error = { fg = colors.red },

              StorageClass = { fg = colors.peach },
              Tag = { fg = colors.peach },
              Label = { fg = colors.peach },
              Structure = { fg = colors.peach },
              Operator = { fg = colors.peach },
              Title = { fg = colors.peach },

              Special = { fg = colors.yellow },
              SpecialChar = { fg = colors.yellow },

              Type = { fg = colors.yellow, style = { "bold" } },
              Function = { fg = colors.green, style = { "bold" } },
              Delimiter = { fg = colors.subtext1 },
              Ignore = { fg = colors.subtext1 },
              Macro = { fg = colors.teal },

              -- Treesitter captures (names per :h treesitter-highlight-groups)
              ["@attribute"] = { fg = colors.mauve },
              ["@boolean"] = { fg = colors.mauve },
              ["@character"] = { fg = colors.teal },
              ["@character.special"] = { link = "SpecialChar" },
              ["@comment"] = { link = "Comment" },
              ["@comment.todo"] = { link = "Todo" },
              ["@constant"] = { fg = colors.text },
              ["@constant.builtin"] = { fg = colors.mauve },
              ["@constant.macro"] = { fg = colors.mauve },
              ["@constructor"] = { fg = colors.green },
              ["@diff.plus"] = { link = "diffAdded" },
              ["@diff.minus"] = { link = "diffRemoved" },
              ["@function"] = { fg = colors.green },
              ["@function.builtin"] = { fg = colors.green },
              ["@function.call"] = { fg = colors.green },
              ["@function.macro"] = { fg = colors.green },
              ["@function.method"] = { fg = colors.green },
              ["@function.method.call"] = { fg = colors.green },
              ["@keyword"] = { fg = colors.red },
              ["@keyword.conditional"] = { fg = colors.red },
              ["@keyword.debug"] = { link = "Debug" },
              ["@keyword.directive"] = { link = "PreProc" },
              ["@keyword.directive.define"] = { link = "Define" },
              ["@keyword.exception"] = { fg = colors.red },
              ["@keyword.function"] = { fg = colors.red },
              ["@keyword.import"] = { fg = colors.red },
              ["@keyword.modifier"] = { fg = colors.peach },
              ["@keyword.operator"] = { fg = colors.peach },
              ["@keyword.repeat"] = { fg = colors.red },
              ["@keyword.return"] = { fg = colors.red },
              ["@label"] = { fg = colors.peach },
              ["@markup.heading"] = { link = "Title" },
              ["@markup.link"] = { link = "Constant" },
              ["@markup.link.url"] = { fg = colors.blue },
              ["@markup.list.unchecked"] = { link = "Ignore" },
              ["@markup.math"] = { fg = colors.blue },
              ["@markup.raw"] = { link = "String" },
              ["@markup.strikethrough"] = { fg = colors.subtext1 },
              ["@module"] = { fg = colors.yellow },
              ["@number"] = { fg = colors.mauve },
              ["@number.float"] = { fg = colors.mauve },
              ["@operator"] = { fg = colors.peach },
              ["@property"] = { fg = colors.blue },
              ["@punctuation.bracket"] = { fg = colors.text },
              ["@punctuation.delimiter"] = { link = "Delimiter" },
              ["@punctuation.special"] = { fg = colors.blue },
              ["@string"] = { fg = colors.teal },
              ["@string.escape"] = { fg = colors.green },
              ["@string.regexp"] = { fg = colors.green },
              ["@string.special"] = { link = "SpecialChar" },
              ["@string.special.symbol"] = { fg = colors.text },
              ["@tag"] = { fg = colors.peach },
              ["@tag.attribute"] = { fg = colors.green },
              ["@tag.delimiter"] = { fg = colors.green },
              ["@type"] = { fg = colors.yellow, style = { "bold" } },
              ["@type.builtin"] = { fg = colors.yellow, style = { "bold" } },
              ["@type.definition"] = { fg = colors.yellow, style = { "bold" } },
              ["@variable"] = { fg = colors.text },
              ["@variable.builtin"] = { fg = colors.mauve },
              ["@variable.member"] = { fg = colors.blue },
              ["@variable.parameter"] = { fg = colors.text },

              -- LSP semantic tokens follow the treesitter captures above
              ["@lsp.type.class"] = { link = "@type" },
              ["@lsp.type.comment"] = { link = "@comment" },
              ["@lsp.type.decorator"] = { link = "@function" },
              ["@lsp.type.enum"] = { link = "@type" },
              ["@lsp.type.enumMember"] = { link = "@property" },
              ["@lsp.type.events"] = { link = "@label" },
              ["@lsp.type.function"] = { link = "@function" },
              ["@lsp.type.interface"] = { link = "@type" },
              ["@lsp.type.keyword"] = { link = "@keyword" },
              ["@lsp.type.macro"] = { link = "@constant.macro" },
              ["@lsp.type.method"] = { link = "@function.method" },
              ["@lsp.type.modifier"] = { link = "@keyword.modifier" },
              ["@lsp.type.namespace"] = { link = "@module" },
              ["@lsp.type.number"] = { link = "@number" },
              ["@lsp.type.operator"] = { link = "@operator" },
              ["@lsp.type.parameter"] = { link = "@variable.parameter" },
              ["@lsp.type.property"] = { link = "@property" },
              ["@lsp.type.regexp"] = { link = "@string.regexp" },
              ["@lsp.type.string"] = { link = "@string" },
              ["@lsp.type.struct"] = { link = "@type" },
              ["@lsp.type.type"] = { link = "@type" },
              ["@lsp.type.typeParameter"] = { link = "@type.definition" },
              ["@lsp.type.variable"] = { link = "@variable" },
            }
          end,
        },
      })
    end,
  },
  {
    "navarasu/onedark.nvim",
    lazy = false, -- the active theme; the only colorscheme loaded at startup
    priority = 1000,
    config = function()
      require("onedark").setup({
        -- Default theme style. Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
        style = "deep",
        term_colors = true, -- Change terminal color as per the selected theme style
        transparent = true,

        -- toggle theme style ---
        toggle_style_key = "<leader>Tt", -- keybind to toggle theme style. Leave it nil to disable it, or set it to a string, for example "<leader>ts"
        toggle_style_list = { "dark", "darker", "cool", "deep", "warm", "warmer", "light" }, -- List of styles to toggle between

        -- Change code style ---
        code_style = {
          comments = "italic",
          keywords = "none",
          functions = "none",
          strings = "none",
          variables = "none",
        },
        colors = {
          bright_orange = "#ff8800",
          text = "#cdd6f4",
          str = "#82d547",
          cursorline = "#2c313c",
        },

        highlights = {
          CursorLineFold = { fg = "$bright_orange", fmt = "bold" },
          CursorLineNr = { fg = "$bright_orange", fmt = "bold" },
          CursorLineSign = { fg = "$bright_orange", fmt = "bold" },
          CursorLine = { bg = "$cursorline" },
          -- Make statusline/lualine background transparent
          StatusLine = { bg = "none" },
          -- make the hidden chars (listchars) foreground colour more subtle
          NonText = { fg = "#cccccc" },
          SpecialKey = { fg = "#cccccc" },

          String = { fg = "$str" },
          ["@string"] = { fg = "$str" },

          Pmenu = { bg = "none" },
          NormalFloat = { bg = "none" },
          FloatBorder = { fg = "$text", bg = "none" },

          SnacksPickerBorder = { fg = "$text" },
          SnacksPickerCursorLine = { bg = "$cursorline" },
          SnacksPickerListCursorLine = { bg = "$cursorline" },
          SnacksPickerPreviewCursorLine = { bg = "$cursorline" },

          WhichKeyTitle = { fg = "$text" },
          WhichKey = { fg = "$text" },

          LspReferenceText = { fg = "none", bg = "none", fmt = "bold" },
          LspReferenceRead = { fg = "none", bg = "none", fmt = "bold" },
          LspReferenceWrite = { fg = "none", bg = "none", fmt = "bold" },

          IlluminatedWordText = { fg = "none", bg = "none", fmt = "bold" },
          IlluminatedWordRead = { fg = "none", bg = "none", fmt = "bold" },
          IlluminatedWordWrite = { fg = "none", bg = "none", fmt = "bold" },
        },

        -- Lualine options --
        lualine = {
          transparent = true, -- lualine center bar transparency
        },

        -- Plugins Config --
        diagnostics = {
          darker = true, -- darker colors for diagnostic
          undercurl = true, -- use undercurl instead of underline for diagnostics
          background = true, -- use background color for virtual text
        },
      })
      require("onedark").load()
    end,
  },
  {
    "folke/tokyonight.nvim",
    lazy = true, -- alternative theme; loaded on :colorscheme tokyonight
    opts = {
      style = "storm",
      transparent = true,
      terminal_colors = true,
      -- styles = {
      --   floats = "transparent",
      --   sidebars = "transparent",
      -- },
      -- on_highlights = function(hl, c)
      --   -- hl.Pmenu = { bg = "none" }
      --   -- hl.NormalFloat = { bg = "none" }
      --   hl.CursorLineFold = { fg = c.fg_dark, bold = true }
      --   hl.CursorLineNr = { fg = c.fg_dark, bold = true }
      --   hl.CursorLineSign = { fg = c.fg_dark, bold = true }
      --   -- hl.LineNr = { fg = c.fg_gutter }
      -- end,
    },
  },
}
