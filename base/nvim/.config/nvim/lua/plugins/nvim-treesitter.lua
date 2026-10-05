local ensure_installed = {
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
}

-- TS indent can misbehave for these:
local indent_disabled = { "python", "yaml", "markdown" }

local select_textobjects = {
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
}

local move_textobjects = {
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
}

-- custom function to disable treesitter on large files
local function disable_on_large(lang, buf)
  local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  local is_disabled = ok and stats and stats.size > 2 * 1024 * 1024 -- >2MB
  if is_disabled then
    vim.schedule(
      function() vim.notify(string.format("Treesitter disabled for %s (file >2MB)", lang or "unknown"), vim.log.levels.WARN, { title = "nvim-treesitter" }) end
    )
  end
  return is_disabled
end

local function set_keymaps(buf, lang)
  -- incremental selection, on the core `an` (parent node) and `in` (child node)
  vim.keymap.set("n", "<leader>vv", "van", { buf = buf, remap = true, desc = "Start incremental selection" })
  vim.keymap.set("x", "+", "an", { buf = buf, remap = true, desc = "Grow selection to parent node" })
  vim.keymap.set("x", "-", "in", { buf = buf, remap = true, desc = "Shrink selection to child node" })

  if not vim.treesitter.query.get(lang, "textobjects") then
    return
  end
  local select = require("nvim-treesitter-textobjects.select")
  for lhs, obj in pairs(select_textobjects) do
    vim.keymap.set({ "x", "o" }, lhs, function() select.select_textobject(obj.query, "textobjects") end, { buf = buf, desc = obj.desc })
  end
  local move = require("nvim-treesitter-textobjects.move")
  for fn, maps in pairs(move_textobjects) do
    for lhs, obj in pairs(maps) do
      vim.keymap.set({ "n", "x", "o" }, lhs, function() move[fn](obj.query, "textobjects") end, { buf = buf, desc = obj.desc })
    end
  end
end

local function attach(buf, lang)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.treesitter.language.add(lang) then
    return
  end
  if vim.treesitter.query.get(lang, "highlights") and not disable_on_large(lang, buf) then
    vim.treesitter.start(buf, lang)
    if lang == "markdown" then
      vim.bo[buf].syntax = "ON"
    end
  end
  if not vim.list_contains(indent_disabled, lang) and vim.treesitter.query.get(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  set_keymaps(buf, lang)
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
    lazy = false,
    build = {
      -- master compiled parsers into the plugin dir; main installs them under stdpath("data")/site
      function(plugin)
        vim.fn.delete(plugin.dir .. "/parser", "rf")
        vim.fn.delete(plugin.dir .. "/parser-info", "rf")
      end,
      ":TSUpdate",
    },
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    },
    config = function()
      local ts = require("nvim-treesitter")
      ts.install(ensure_installed)

      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
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
          set_jumps = true,
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang then
            return
          end
          if vim.treesitter.language.add(lang) then
            attach(args.buf, lang)
          elseif vim.list_contains(ts.get_available(), lang) then
            ts.install(lang):await(function()
              vim.schedule(function() attach(args.buf, lang) end)
            end)
          end
        end,
      })
    end,
  },
}
