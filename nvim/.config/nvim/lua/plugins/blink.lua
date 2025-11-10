return {
  { "L3MON4D3/LuaSnip", keys = {} },
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    version = "*",
    config = function()
      require("blink.cmp").setup({
        snippets = { preset = "luasnip" },
        sources = {
          per_filetype = {
            codecompanion = { "codecompanion" },
          },
          default = { "lazydev", "lsp", "path", "snippets", "buffer" },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              -- make lazydev completions top priority (see `:h blink.cmp`)
              score_offset = 100,
              -- path completion from cwd instead of current buffer’s directory
            },
            path = {
              opts = {
                get_cwd = function(_) return vim.fn.getcwd() end,
              },
            },
            cmdline = {
              min_keyword_length = 2,
            },
          },
        },
        cmdline = {
          completion = { menu = { auto_show = true } },
          keymap = {
            ["<Up>"] = { "select_prev", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
          },
        },
        completion = {
          list = {
            selection = {
              preselect = false,
              auto_insert = false,
            },
          },
          -- Configure how the menu looks; icon order, borders etc..
          menu = {

            border = "rounded",
            scrolloff = 1,
            draw = {
              columns = {
                { "kind_icon" },
                { "label", "label_description", gap = 1 },
                { "kind" },
                { "source_name" },
              },
            },
          },

          -- Show documentation when selecting a completion item
          documentation = {
            window = {
              border = "rounded",
            },
            auto_show = true,
            auto_show_delay_ms = 500,
          },

          -- Display a preview of the selected item on the current line
          ghost_text = { enabled = true, menu = { auto_show = false } },
        },

        -- Experimental signature help support
        -- signature = { window = { border = "rounded" }, enabled = true },
      })
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
