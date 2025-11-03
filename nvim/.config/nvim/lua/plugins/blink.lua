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
            },
            cmdline = {
              min_keyword_length = 2,
            },
          },
        },
        cmdline = {
          completion = { menu = { auto_show = true } },
          keymap = {
            ["<CR>"] = { "accept_and_enter", "fallback" },
          },
        },
        completion = {
          menu = {
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
          documentation = {
            window = {
              border = "rounded",
            },
            auto_show = true,
            auto_show_delay_ms = 500,
          },
        },
      })
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
