-- nvim-treesitter and nvim-treesitter-textobjects, `main` branch API.
--
-- The `main` branch (required on Neovim >= 0.12) dropped the `master` module
-- system: there is no `nvim-treesitter.configs`, no `ensure_installed`, no
-- `highlight`/`indent`/`incremental_selection`/`textobjects` tables. The plugin
-- now only installs parsers and queries; highlighting and indentation are
-- enabled per buffer from a FileType autocmd with Neovim's own
-- `vim.treesitter` API, and textobjects are plain keymaps.

-- Parsers that are always installed (formerly `ensure_installed`).
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

-- Treesitter indentation misbehaves for these filetypes; keep the builtin indent.
local indent_disabled = { python = true, yaml = true, markdown = true }

-- Keep the legacy vim regex highlighting on top of treesitter for these filetypes
-- (formerly `additional_vim_regex_highlighting`).
local extra_regex_highlighting = { markdown = true }

-- Skip treesitter entirely for files bigger than this.
local max_filesize = 2 * 1024 * 1024 -- 2MB

---@param buf integer
---@return boolean
local function is_large_file(buf)
  local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
  return ok and stats ~= nil and stats.size > max_filesize
end

-- Select textobjects: key -> query (all in the "textobjects" query group).
local select_keymaps = {
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

-- Move keymaps, grouped by the `nvim-treesitter-textobjects.move` function they call.
local move_keymaps = {
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

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
    -- The main branch does not support lazy-loading: its plugin/ files register
    -- the filetype -> language mappings and the :TS* commands, and the FileType
    -- autocmd below must exist before the first buffer is loaded.
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      -- Defaults: parsers and queries go to stdpath("data") .. "/site".
      ts.setup({})

      -- Parsers are compiled locally, which needs the tree-sitter CLI, tar, curl and a
      -- C compiler (see :checkhealth nvim-treesitter).
      local function has_cli() return vim.fn.executable("tree-sitter") == 1 end

      local available ---@type table<string, true>?
      ---@param lang string
      ---@return boolean
      local function is_available(lang)
        if not available then
          available = {}
          for _, l in ipairs(ts.get_available()) do
            available[l] = true
          end
        end
        return available[lang] == true
      end

      -- Install tasks still running, by language, so a buffer opened while its parser is
      -- being built attaches when the build finishes instead of starting a second build.
      local pending = {} ---@type table<string, table>

      ---@param langs string[]
      ---@return table task
      local function install(langs)
        local task = ts.install(langs)
        for _, lang in ipairs(langs) do
          pending[lang] = task
        end
        task:await(function()
          for _, lang in ipairs(langs) do
            pending[lang] = nil
          end
        end)
        return task
      end

      if has_cli() then
        -- Install missing parsers in the background; already-installed ones are skipped.
        install(ensure_installed)
      else
        vim.schedule(
          function()
            vim.notify(
              "tree-sitter CLI not found; parsers cannot be installed. See :checkhealth nvim-treesitter",
              vim.log.levels.WARN,
              { title = "nvim-treesitter" }
            )
          end
        )
      end

      ---@param buf integer
      ---@param ft string
      ---@param lang string
      local function attach(buf, ft, lang)
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        vim.treesitter.start(buf, lang)
        if extra_regex_highlighting[ft] then
          vim.bo[buf].syntax = "ON"
        end
        if not indent_disabled[ft] then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        desc = "Enable treesitter highlighting and indentation",
        callback = function(ev)
          local buf, ft = ev.buf, ev.match
          local lang = vim.treesitter.language.get_lang(ft)
          if not lang then
            return
          end

          if is_large_file(buf) then
            vim.schedule(
              function() vim.notify(string.format("Treesitter disabled for %s (file >2MB)", lang), vim.log.levels.WARN, { title = "nvim-treesitter" }) end
            )
            return
          end

          if vim.treesitter.language.add(lang) then
            attach(buf, ft, lang)
            return
          end

          -- No parser yet: wait for a build already in progress, or fetch the parser if
          -- nvim-treesitter knows the language (formerly `auto_install`), then attach once
          -- the build finishes. Unknown languages are ignored.
          local task = pending[lang]
          if not task then
            if not has_cli() or not is_available(lang) then
              return
            end
            task = install({ lang })
          end
          task:await(function(err)
            vim.schedule(function()
              if err then
                return -- nvim-treesitter already logged it
              end
              if vim.treesitter.language.add(lang) and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == ft then
                attach(buf, ft, lang)
              end
            end)
          end)
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    version = false,
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
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

      local select = require("nvim-treesitter-textobjects.select")
      for lhs, spec in pairs(select_keymaps) do
        vim.keymap.set({ "x", "o" }, lhs, function() select.select_textobject(spec.query, "textobjects") end, { desc = spec.desc })
      end

      local move = require("nvim-treesitter-textobjects.move")
      for method, maps in pairs(move_keymaps) do
        for lhs, spec in pairs(maps) do
          vim.keymap.set({ "n", "x", "o" }, lhs, function() move[method](spec.query, "textobjects") end, { desc = spec.desc })
        end
      end
    end,
  },
}
