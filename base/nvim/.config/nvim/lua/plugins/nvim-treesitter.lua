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
}

-- TS indent can misbehave for these:
local indent_disabled = { "python", "yaml", "markdown" }

local select_textobjects = {
  -- Core text objects (well-supported for selection)
  ["af"] = { query = "@function.outer", desc = "Around function" },
  ["if"] = { query = "@function.inner", desc = "Inside function" },
  ["ac"] = { query = "@class.outer", desc = "Around class" },
  ["ic"] = { query = "@class.inner", desc = "Inside class" },
  ["ai"] = { query = "@conditional.outer", desc = "Around conditional" },
  ["ii"] = { query = "@conditional.inner", desc = "Inside conditional" },
  ["al"] = { query = "@loop.outer", desc = "Around loop" },
  ["il"] = { query = "@loop.inner", desc = "Inside loop" },
  ["ap"] = { query = "@parameter.outer", desc = "Around parameter" },
  ["ip"] = { query = "@parameter.inner", desc = "Inside parameter" },
  ["ab"] = { query = "@block.outer", desc = "Around block" },
  ["ib"] = { query = "@block.inner", desc = "Inside block" },

  -- Additional useful text objects
  ["a/"] = { query = "@comment.outer", desc = "Around comment" },
  ["aa"] = { query = "@call.outer", desc = "Around function call" },
  ["ia"] = { query = "@call.inner", desc = "Inside function call" },
  ["ar"] = { query = "@return.outer", desc = "Around return" },
  ["ir"] = { query = "@return.inner", desc = "Inside return" },
}

local move_textobjects = {
  goto_previous_start = {
    ["[f"] = { query = "@function.outer", desc = "Previous function" },
    ["[c"] = { query = "@class.outer", desc = "Previous class" },
    ["[p"] = { query = "@parameter.inner", desc = "Previous parameter" },
    ["[b"] = { query = "@block.outer", desc = "Previous block" },
    ["[i"] = { query = "@conditional.outer", desc = "Previous conditional" },
    ["[l"] = { query = "@loop.outer", desc = "Previous loop" },
    ["[a"] = { query = "@call.outer", desc = "Previous function call" },
    ["[r"] = { query = "@return.outer", desc = "Previous return" },
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

local ts_toggle -- set in config: Snacks is not loaded yet when lazy reads this spec

local function set_keymaps(buf)
  -- incremental selection, on the core `an` (parent node) and `in` (child node)
  vim.keymap.set("n", "<leader>v", "van", { buf = buf, remap = true, desc = "Start incremental selection" })
  vim.keymap.set("x", "+", "an", { buf = buf, remap = true, desc = "Grow selection to parent node" })
  vim.keymap.set("x", "-", "in", { buf = buf, remap = true, desc = "Shrink selection to child node" })
  ts_toggle:map("<leader>TT", { buf = buf })
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
  set_keymaps(buf)
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
      -- one which-key spec, with the toggle's live label and icon, for the key mapped in every buffer
      ts_toggle = Snacks.toggle.treesitter({ which_key = false })
      Snacks.util.on_module("which-key", function() ts_toggle:_wk("<leader>TT", "n") end)
      -- on the first start lazy runs this config inside its install wait, where the install log raises a hit-enter prompt
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function() ts.install(ensure_installed) end,
      })

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
      require("config.textobjects").setup(select_textobjects, move_textobjects)

      local installs = {} -- language -> its one install task this session, so a failed build is not retried per buffer
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match)
          if lang and vim.treesitter.language.add(lang) then
            attach(args.buf, lang)
            return
          end
          pcall(vim.keymap.del, "n", "<leader>TT", { buf = args.buf })
          if lang and vim.list_contains(ts.get_available(), lang) then
            installs[lang] = installs[lang] or ts.install(lang)
            installs[lang]:await(function()
              vim.schedule(function() attach(args.buf, lang) end)
            end)
          end
        end,
      })
    end,
  },
}
