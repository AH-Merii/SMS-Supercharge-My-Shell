--------------------------------------------------------------------------
-- Custom rule snippets (pure helpers + lazy requires inside builders)
--------------------------------------------------------------------------

--- Build the "space inside pair" rule for a single bracket pair.
---
--- For (open, close), e.g. "(", ")":
--- - Typing a space between them turns `()` into `(  )` with the cursor centered.
--- - Backspacing between the two spaces deletes both spaces → `()`.
local function smart_space_rule(open, close)
  local Rule = require("nvim-autopairs.rule")
  local cond = require("nvim-autopairs.conds")

  return Rule(" ", " ")
    :with_pair(function(opts)
      local pair = opts.line:sub(opts.col - 1, opts.col)
      return pair == open .. close
    end)
    :with_move(cond.none())
    :with_cr(cond.none())
    :with_del(function(opts)
      -- Only delete both spaces when the cursor is exactly between them:
      -- e.g. "(  )" with cursor at "( | )"
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local context = opts.line:sub(col - 1, col + 2)
      return context == (open .. "  " .. close)
    end)
end

--- Build the "movement + <CR> inside spaced pair" rule for a single bracket pair.
---
--- For (open, close), e.g. "(", ")":
--- - Typing the closing bracket inside "(  )" jumps over the existing closer
---   instead of inserting another one.
--- - Pressing <CR> inside "(  )" removes extra spaces and keeps formatting tidy.
local function smart_movement_rule(open, close)
  local Rule = require("nvim-autopairs.rule")
  local cond = require("nvim-autopairs.conds")

  return Rule(open .. " ", " " .. close)
    :with_pair(cond.none())
    -- Jump over existing closer: "(  |)" + ")" → "(  )|"
    :with_move(function(opts) return opts.char == close end)
    :with_del(cond.none())
    :use_key(close)
    -- Clean up inner spaces when pressing Enter inside "(  )", "[  ]", "{  }".
    -- This avoids leaving stray spaces around the newline.
    :replace_map_cr(
      function(_) return "<C-c>2xi<CR><C-c>O" end
    )
end

--- Convenience helper: return both smart-spacing rules for a single pair.
local function smart_spacing_rules_for_pair(open, close)
  return {
    smart_space_rule(open, close),
    smart_movement_rule(open, close),
  }
end

--- Build smart-spacing rules for common bracket types.
local function smart_spacing_rules()
  local rules = {}
  local pairs = {
    { "(", ")" },
    { "[", "]" },
    { "{", "}" },
  }

  for _, p in ipairs(pairs) do
    vim.list_extend(rules, smart_spacing_rules_for_pair(p[1], p[2]))
  end

  return rules
end

--- Build a "move past existing char" rule (no pairing / deleting / CR behavior).
local function move_past_char(char)
  local Rule = require("nvim-autopairs.rule")
  local cond = require("nvim-autopairs.conds")

  return {
    Rule("", char)
      :with_move(function(opts) return opts.char == char end)
      :with_pair(function() return false end)
      :with_del(function() return false end)
      :with_cr(function() return false end)
      :use_key(char),
  }
end

--- Build a smart rule for angle brackets `< >` used in generics or templates.
---
--- Behavior:
--- - Inserts `>` automatically after `<` **only** when typing after an identifier
---   or scope operator (e.g., `std::vector<|>` in C++).
--- - Skips auto-pairing in HTML/JSX/TSX where `<` starts a tag.
--- - Moves cursor over an existing `>` instead of inserting a duplicate.
local function smart_angle_bracket_rule()
  local Rule = require("nvim-autopairs.rule")
  local cond = require("nvim-autopairs.conds")

  return Rule("<", ">", {
    "-html",
    "-javascriptreact",
    "-typescriptreact",
  }):with_pair(cond.before_regex("%a+:?:?$", 3)):with_move(function(opts) return opts.char == ">" end)
end

--------------------------------------------------------------------------
-- Trailing comma helpers
--------------------------------------------------------------------------

--- Helper: only allow the pair if we are *not* followed by a comma.
--- Uses opts.next_char provided by nvim-autopairs.
local function not_followed_by_comma(opts)
  local next = opts.next_char or ""
  return not next:match("^%s*,")
end

--- Generic builder for "close + comma" rules inside comma-separated collections.
---
--- For example:
---   collection_trailing_comma_rule("lua", "{", "}", { "table_constructor" })
--- will create a rule that turns `{ |` into `{|},` only when inside a Lua
--- `table_constructor` node and only if the next non-space char is not already `,`.
---
--- Params:
--- - ft       : filetype string (e.g. "lua", "python")
--- - open     : opening delimiter (e.g. "{", "(", "[", "'", '"')
--- - close    : closing delimiter (e.g. "}", ")", "]", "'", '"')
--- - ts_nodes : list of Treesitter node names where this rule is allowed
local function collection_trailing_comma_rule(ft, open, close, ts_nodes)
  local Rule = require("nvim-autopairs.rule")
  local ts_conds = require("nvim-autopairs.ts-conds")

  return Rule(open, close .. "+", ft):with_pair(ts_conds.is_ts_node(ts_nodes)):with_pair(not_followed_by_comma)
end

--------------------------------------------------------------------------
-- Lua
--------------------------------------------------------------------------

--- Lua: table constructors with trailing commas for `{}`, quoted keys, etc.
local function lua_table_trailing_comma_rules()
  local nodes = { "table_constructor" }

  return {
    collection_trailing_comma_rule("lua", "{", "}", nodes),
    collection_trailing_comma_rule("lua", "'", "'", nodes),
    collection_trailing_comma_rule("lua", '"', '"', nodes),
  }
end

--------------------------------------------------------------------------
-- Python
--------------------------------------------------------------------------

--- Python: lists, dicts, and tuples.
--- Node names are based on tree-sitter-python and may need tweaking:
---   - "list"
---   - "dictionary"
---   - "tuple"
local function python_trailing_comma_rules()
  local list_dict_nodes = { "list", "dictionary", "tuple" }
  local tuple_nodes = { "tuple" }

  return {
    collection_trailing_comma_rule("python", "[", "]", list_dict_nodes),
    collection_trailing_comma_rule("python", "{", "}", list_dict_nodes),
    collection_trailing_comma_rule("python", "(", ")", tuple_nodes),
  }
end

--------------------------------------------------------------------------
-- JavaScript / TypeScript / React / Vue / Svelte / Astro
--------------------------------------------------------------------------

--- JS ecosystem: arrays and objects.
--- Covers common front-end filetypes that share array/object syntax.
--- Node names assume tree-sitter grammars that use "array" and "object".
local function javascript_trailing_comma_rules()
  local nodes = { "array", "object" }

  -- Common JS-family filetypes
  local filetypes = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "vue",
    "astro",
    "svelte",
  }

  local rules = {}

  for _, ft in ipairs(filetypes) do
    vim.list_extend(rules, {
      collection_trailing_comma_rule(ft, "[", "]", nodes),
      collection_trailing_comma_rule(ft, "{", "}", nodes),
    })
  end

  return rules
end

--------------------------------------------------------------------------
-- Aggregate rules
--------------------------------------------------------------------------

local function all_custom_rules()
  local rules = {}

  -- Smart spacing for (), [], {}
  vim.list_extend(rules, smart_spacing_rules())

  -- Angle brackets for generics/templates
  table.insert(rules, smart_angle_bracket_rule())

  -- Trailing commas
  vim.list_extend(rules, lua_table_trailing_comma_rules())
  vim.list_extend(rules, python_trailing_comma_rules())
  vim.list_extend(rules, javascript_trailing_comma_rules())

  -- Example: move past specific chars if you want (not used by default)
  -- vim.list_extend(rules, move_past_char(";"))

  return rules
end

return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      fast_wrap = {},
      disable_filetype = { "trouble", "oil" },
    },
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      local ts_conds = require("nvim-autopairs.ts-conds")
      npairs.setup(opts)

      --- Disable builtin nvim-autopairs rules for specific chars *only inside*
      --- certain Treesitter nodes for a given filetype or group of filetypes.
      ---
      --- You can pass either:
      ---   disable_builtin_rules_in_nodes("lua", { "{", "'", '"' }, { "table_constructor" })
      --- or a list of langs:
      ---   disable_builtin_rules_in_nodes({ "javascript", "typescript" }, { "{", "[" }, { "array", "object" })
      ---
      --- It disables built-in pairing inside the specified nodes,
      --- so that custom rules can take over, while leaving default
      --- behavior untouched elsewhere.
      local function disable_builtin_rules_in_nodes(langs, chars, ts_nodes)
        if type(langs) == "string" then
          langs = { langs }
        end

        local in_nodes = ts_conds.is_ts_node(ts_nodes)

        for _, ch in ipairs(chars) do
          local rules = npairs.get_rules(ch)

          for _, rule in ipairs(rules) do
            rule:with_pair(function(_)
              -- If current filetype isn't in the target list → no change
              if not vim.tbl_contains(langs, vim.bo.filetype) then
                print("true")
                return true
              end
              -- Inside specified nodes → disable built-in rule
              if in_nodes(_) then
                print("false")
                return false
              end
              print("true 2")
              return true
            end)
          end
        end
      end

      local js_filetypes = {
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "vue",
        "astro",
        "svelte",
      }

      disable_builtin_rules_in_nodes("lua", { "{", "'", '"' }, { "table_constructor" })
      disable_builtin_rules_in_nodes("python", { "[", "{" }, { "list", "dictionary", "tuple" })
      disable_builtin_rules_in_nodes("python", { "(" }, { "tuple" })

      disable_builtin_rules_in_nodes(js_filetypes, { "[", "{", "(" }, { "array", "object" })

      npairs.add_rules(python_trailing_comma_rules())

      npairs.add_rules(lua_table_trailing_comma_rules())

      -- Register all custom rules once autopairs is loaded
      npairs.add_rules(all_custom_rules())
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
