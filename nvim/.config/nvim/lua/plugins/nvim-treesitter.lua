return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      -- custom function to disable treesitter on large files
      local function disable_on_large(lang, buf)
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
        local is_disabled = ok and stats and stats.size > 2 * 1024 * 1024 -- >2MB
        if is_disabled then
          vim.schedule(function()
            vim.notify(
              string.format("Treesitter disabled for %s (file >2MB)", lang or "unknown"),
              vim.log.levels.WARN,
              { title = "nvim-treesitter" }
            )
          end)
        end
        return is_disabled
      end

      require("nvim-treesitter.configs").setup({
        sync_install = false,
        modules = {},
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { "markdown" },
          disable = disable_on_large,
        },
        indent = {
          enable = true,
          -- TS indent can misbehave for these:
          disable = { "python", "yaml", "markdown" },
        },
        auto_install = true,
        ensure_installed = {
          "bash",
          "c",
          "html",
          "javascript",
          "json",
          "lua",
          "luadoc",
          "luap",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "regex",
          "tsx",
          "typescript",
          "vim",
          "vimdoc",
          "yaml",
          "rust",
          "go",
          "gomod",
          "gowork",
          "gosum",
          "terraform",
          "proto",
          "zig",
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<leader>vv",
            node_incremental = "+",
            scope_incremental = false,
            node_decremental = "-",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,

            keymaps = {
              -- Core text objects (well-supported for selection)
              ["af"] = { query = "@function.outer", desc = "around a function" },
              ["if"] = { query = "@function.inner", desc = "inner part of a function" },
              ["ac"] = { query = "@class.outer", desc = "around a class" },
              ["ic"] = { query = "@class.inner", desc = "inner part of a class" },
              ["ai"] = { query = "@conditional.outer", desc = "around an if statement" },
              ["ii"] = { query = "@conditional.inner", desc = "inner part of an if statement" },
              ["al"] = { query = "@loop.outer", desc = "around a loop" },
              ["il"] = { query = "@loop.inner", desc = "inner part of a loop" },
              ["ap"] = { query = "@parameter.outer", desc = "around parameter" },
              ["ip"] = { query = "@parameter.inner", desc = "inside a parameter" },
              ["ab"] = { query = "@block.outer", desc = "around block" },
              ["ib"] = { query = "@block.inner", desc = "inside block" },

              -- Additional useful text objects
              ["a/"] = { query = "@comment.outer", desc = "around comment" },
              ["aa"] = { query = "@call.outer", desc = "around function call" },
              ["ia"] = { query = "@call.inner", desc = "inside function call" },
              ["ar"] = { query = "@return.outer", desc = "around return statement" },
              ["ir"] = { query = "@return.inner", desc = "inside return statement" },
            },
            selection_modes = {
              ["@parameter.outer"] = "v",
              ["@parameter.inner"] = "v",
              ["@function.outer"] = "v",
              ["@conditional.outer"] = "v",
              ["@loop.outer"] = "v",
              ["@class.outer"] = "<c-v>",
              ["@block.outer"] = "v",
              ["@call.outer"] = "v",
              ["@comment.outer"] = "v",
              ["@assignment.outer"] = "v",
              ["@return.outer"] = "v",
            },
            include_surrounding_whitespace = true,
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_previous_start = {
              ["[f"] = { query = "@function.outer", desc = "previous function" },
              ["[c"] = { query = "@class.outer", desc = "previous class" },
              ["[p"] = { query = "@parameter.inner", desc = "previous parameter" },
              ["[b"] = { query = "@block.outer", desc = "previous block" },
              ["[i"] = { query = "@conditional.outer", desc = "previous conditional" },
              ["[l"] = { query = "@loop.outer", desc = "previous loop" },
              ["[a"] = { query = "@call.outer", desc = "previous function call" },
              ["[r"] = { query = "@return.outer", desc = "previous return" },
              ["[/"] = { query = "@comment.outer", desc = "Previous comment" },
            },
            goto_next_start = {
              ["]f"] = { query = "@function.outer", desc = "Next function" },
              ["]c"] = { query = "@class.outer", desc = "Next class" },
              ["]p"] = { query = "@parameter.inner", desc = "Next parameter" },
              ["]b"] = { query = "@block.outer", desc = "Next block" },
              ["]i"] = { query = "@conditional.outer", desc = "Next conditional" },
              ["]l"] = { query = "@loop.outer", desc = "Next loop" },
              ["]a"] = { query = "@call.outer", desc = "Next function call" },
              ["]r"] = { query = "@return.outer", desc = "Next return" },
              ["]/"] = { query = "@comment.outer", desc = "Next comment" },
            },
            goto_previous_end = {
              ["[F"] = { query = "@function.outer", desc = "Previous function end" },
              ["[C"] = { query = "@class.outer", desc = "Previous class end" },
              ["[B"] = { query = "@block.outer", desc = "Previous block end" },
            },
            goto_next_end = {
              ["]F"] = { query = "@function.outer", desc = "Next function end" },
              ["]C"] = { query = "@class.outer", desc = "Next class end" },
              ["]B"] = { query = "@block.outer", desc = "Next block end" },
            },
          },
        },
      })
    end,
  },
}
