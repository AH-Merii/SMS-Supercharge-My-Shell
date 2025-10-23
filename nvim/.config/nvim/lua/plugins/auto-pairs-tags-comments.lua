return {

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      fast_wrap = { map = "<M-e>" },
      disable_filetype = { "trouble", "oil" },
    },
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      npairs.setup(opts)

      --------------------------------------------------------------------------
      -- Custom rule snippets from nvim-autopairs wiki
      --------------------------------------------------------------------------
      local Rule = require("nvim-autopairs.rule")
      local cond = require("nvim-autopairs.conds")
      local ts_conds = require("nvim-autopairs.ts-conds")

      --------------------------------------------------------------------------
      -- Add spaces between parentheses
      --------------------------------------------------------------------------
      local brackets = { { "(", ")" }, { "[", "]" }, { "{", "}" } }
      npairs.add_rules({
        Rule(" ", " ")
          :with_pair(function(opts)
            local pair = opts.line:sub(opts.col - 1, opts.col)
            return vim.tbl_contains({
              brackets[1][1] .. brackets[1][2],
              brackets[2][1] .. brackets[2][2],
              brackets[3][1] .. brackets[3][2],
            }, pair)
          end)
          :with_move(cond.none())
          :with_cr(cond.none())
          :with_del(function(opts)
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local context = opts.line:sub(col - 1, col + 2)
            return vim.tbl_contains({
              brackets[1][1] .. "  " .. brackets[1][2],
              brackets[2][1] .. "  " .. brackets[2][2],
              brackets[3][1] .. "  " .. brackets[3][2],
            }, context)
          end),
      })
      for _, bracket in pairs(brackets) do
        npairs.add_rules({
          Rule(bracket[1] .. " ", " " .. bracket[2])
            :with_pair(cond.none())
            :with_move(function(opts)
              return opts.char == bracket[2]
            end)
            :with_del(cond.none())
            :use_key(bracket[2])
            :replace_map_cr(function(_)
              return "<C-c>2xi<CR><C-c>O"
            end),
        })
      end

      --------------------------------------------------------------------------
      -- Move past commas and semicolons
      --------------------------------------------------------------------------
      for _, punct in pairs({ ",", ";" }) do
        require("nvim-autopairs").add_rules({
          require("nvim-autopairs.rule")("", punct)
            :with_move(function(opts)
              return opts.char == punct
            end)
            :with_pair(function()
              return false
            end)
            :with_del(function()
              return false
            end)
            :with_cr(function()
              return false
            end)
            :use_key(punct),
        })
      end

      --------------------------------------------------------------------------
      -- Auto-pair <> for generics but not as operators
      --------------------------------------------------------------------------
      npairs.add_rule(Rule("<", ">", {
        "-html",
        "-javascriptreact",
        "-typescriptreact",
      }):with_pair(cond.before_regex("%a+:?:?$", 3)):with_move(function(opts)
        return opts.char == ">"
      end))

      --------------------------------------------------------------------------
      --  Add trailing commas to "'} inside Lua tables
      --------------------------------------------------------------------------
      npairs.add_rules({
        Rule("{", "},", "lua"):with_pair(ts_conds.is_ts_node({ "table_constructor" })),
        Rule("'", "',", "lua"):with_pair(ts_conds.is_ts_node({ "table_constructor" })),
        Rule('"', '",', "lua"):with_pair(ts_conds.is_ts_node({ "table_constructor" })),
      })

      --------------------------------------------------------------------------
      -- Expand multiple pairs on Enter (scoped to JS/TS to avoid surprises)
      --------------------------------------------------------------------------
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "javascript", "typescript", "typescriptreact", "javascriptreact" },
        callback = function()
          local autopairs = require("nvim-autopairs")

          local get_closing_for_line = function(line)
            local i = -1
            local clo = ""

            while true do
              i, _ = string.find(line, "[%(%)%{%}%[%]]", i + 1)
              if i == nil then
                break
              end
              local ch = string.sub(line, i, i)
              local st = string.sub(clo, 1, 1)

              if ch == "{" then
                clo = "}" .. clo
              elseif ch == "}" then
                if st ~= "}" then
                  return ""
                end
                clo = string.sub(clo, 2)
              elseif ch == "(" then
                clo = ")" .. clo
              elseif ch == ")" then
                if st ~= ")" then
                  return ""
                end
                clo = string.sub(clo, 2)
              elseif ch == "[" then
                clo = "]" .. clo
              elseif ch == "]" then
                if st ~= "]" then
                  return ""
                end
                clo = string.sub(clo, 2)
              end
            end

            return clo
          end

          autopairs.remove_rule("(")
          autopairs.remove_rule("{")
          autopairs.remove_rule("[")

          autopairs.add_rule(Rule("[%(%{%[]", "")
            :use_regex(true)
            :replace_endpair(function(opts)
              return get_closing_for_line(opts.line)
            end)
            :end_wise(function(opts)
              return get_closing_for_line(opts.line) ~= ""
            end))
        end,
      })

      --------------------------------------------------------------------------
      -- Auto center current line when inserting <CR> inside {}
      --------------------------------------------------------------------------
      require("nvim-autopairs").get_rule("{"):replace_map_cr(function()
        local res = "<c-g>u<CR><CMD>normal! ====<CR><up><end><CR>"
        local line = vim.fn.winline()
        local height = vim.api.nvim_win_get_height(0)
        if line < height / 3 or height * 2 / 3 < line then
          res = res .. "x<ESC>zzs"
        end
        return res
      end)
    end,
  },
  -- Autotags
  {
    "windwp/nvim-ts-autotag",
    opts = {},
  },

  -- comments
  {
    "numToStr/Comment.nvim",
    opts = {},
    lazy = false,
  },

  -- useful when there are embedded languages in certain types of files (e.g. Vue or React)
  { "joosepalviste/nvim-ts-context-commentstring", lazy = true },
}
