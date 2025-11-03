return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  config = function()
    local lualine = require("lualine")

    -- dynamic Catppuccin palette (fallback if missing)
    local function get_colors()
      local ok, palette = pcall(require, "catppuccin.palettes")
      if ok then
        local c = palette.get_palette()
        return {
          bg = c.mantle,
          fg = c.text,
          red = c.red,
          yellow = c.yellow,
          green = c.green,
          cyan = c.teal,
          blue = c.blue,
          magenta = c.mauve,
          orange = c.peach,
          violet = c.lavender,
        }
      else
        return {
          bg = "#1e1e2e",
          fg = "#cdd6f4",
          red = "#f38ba8",
          yellow = "#f9e2af",
          green = "#a6e3a1",
          cyan = "#94e2d5",
          blue = "#89b4fa",
          magenta = "#cba6f7",
          orange = "#fab387",
          violet = "#b4befe",
        }
      end
    end

    local colors = get_colors()

    local conditions = {
      buffer_not_empty = function()
        return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
      end,
      hide_in_width = function()
        return vim.fn.winwidth(0) > 80
      end,
      check_git_workspace = function()
        local filepath = vim.fn.expand("%:p:h")
        local gitdir = vim.fn.finddir(".git", filepath .. ";")
        return gitdir ~= "" and #gitdir > 0 and #gitdir < #filepath
      end,
    }

    ---------------------------------------------------------------------------
    -- Project root logic
    ---------------------------------------------------------------------------
    local function get_project_root()
      local buf_dir = vim.fn.expand("%:p:h")

      -- try to detect git root
      local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(buf_dir) .. " rev-parse --show-toplevel")[1]

      if git_root and git_root ~= "" then
        return git_root
      end

      -- fallback to Neovim's idea of cwd
      return vim.fn.getcwd()
    end

    ---------------------------------------------------------------------------
    -- Path component with highlight
    --
    -- layout:
    --   <project>/<relative/dirs>/<file>
    --
    -- styles:
    --   project dir   -> magenta, bold
    --   middle path   -> normal fg
    --   filename      -> blue, bold
    --
    -- note: we build statusline highlight chunks manually using %#Group#text%#
    ---------------------------------------------------------------------------
    local function filepath_component()
      if vim.fn.bufname("%") == "" then
        return ""
      end

      local fullpath = vim.fn.expand("%:p")
      local root = get_project_root()

      if not fullpath or not root or fullpath == "" or root == "" then
        return vim.fn.expand("%:t")
      end

      -- path relative to project root
      local rel = fullpath:gsub("^" .. vim.pesc(root) .. "/?", "")

      -- split relative pieces
      local parts = {}
      for seg in string.gmatch(rel, "[^/]+") do
        table.insert(parts, seg)
      end

      local project_name = vim.fn.fnamemodify(root, ":t")
      local filename = parts[#parts] or ""
      local middle_path = ""

      if #parts > 1 then
        middle_path = table.concat(vim.list_slice(parts, 1, #parts - 1), "/")
      end

      local hl_project = "%#LualineProjectRoot#"
      local hl_middle = "%#LualinePath#"
      local hl_file = "%#LualineFilename#"
      local hl_reset = "%#LualineNormal#"

      local out = {}
      -- project
      table.insert(out, hl_project .. project_name .. hl_reset)

      -- middle folders
      if middle_path ~= "" then
        table.insert(out, "/")
        table.insert(out, hl_middle .. middle_path .. hl_reset)
      end

      -- filename
      if filename ~= "" then
        table.insert(out, "/")
        table.insert(out, hl_file .. filename .. hl_reset)
      end

      return table.concat(out, "")
    end

    ---------------------------------------------------------------------------
    -- Highlight groups for statusline segments
    -- we re-define them on ColorScheme so they track your theme
    ---------------------------------------------------------------------------
    local function define_highlights()
      local set_hl = function(name, opts)
        vim.api.nvim_set_hl(0, name, opts)
      end

      -- base group for normal segment bg/fg
      set_hl("LualineNormal", {
        fg = colors.fg,
        bg = colors.bg,
      })

      -- project root: magenta bold
      set_hl("LualineProjectRoot", {
        fg = colors.magenta,
        bg = colors.bg,
        bold = true,
      })

      -- middle path: plain fg
      set_hl("LualinePath", {
        fg = colors.fg,
        bg = colors.bg,
      })

      -- filename: blue bold
      set_hl("LualineFilename", {
        fg = colors.blue,
        bg = colors.bg,
        bold = true,
      })
    end

    define_highlights()

    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        colors = get_colors()
        define_highlights()
      end,
    })

    ---------------------------------------------------------------------------
    -- lualine setup table
    ---------------------------------------------------------------------------
    local config = {
      options = {
        component_separators = "",
        section_separators = "",
        globalstatus = true,
        theme = {
          normal = { c = { fg = colors.fg, bg = colors.bg } },
          inactive = { c = { fg = colors.fg, bg = colors.bg } },
        },
      },
      sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_y = {},
        lualine_z = {},
        lualine_c = {},
        lualine_x = {},
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_y = {},
        lualine_z = {},
        lualine_c = {},
        lualine_x = {},
      },
    }

    local function ins_left(component)
      table.insert(config.sections.lualine_c, component)
    end

    local function ins_right(component)
      table.insert(config.sections.lualine_x, component)
    end

    ---------------------------------------------------------------------------
    -- LEFT side
    ---------------------------------------------------------------------------

    -- mode indicator
    ins_left({
      function()
        return ""
      end,
      color = function()
        local mode_color = {
          n = colors.red,
          i = colors.green,
          v = colors.blue,
          V = colors.blue,
          c = colors.magenta,
          s = colors.orange,
          S = colors.orange,
          R = colors.violet,
          t = colors.red,
        }
        return { fg = mode_color[vim.fn.mode()] or colors.red }
      end,
      padding = { right = 1 },
    })

    -- project-aware path
    ins_left({
      filepath_component,
      cond = conditions.buffer_not_empty,
    })

    -- cursor position (line:col)
    ins_left({ "location" })

    -- file progress (e.g. 42%)
    ins_left({
      "progress",
      color = { fg = colors.fg, gui = "bold" },
    })

    -- diagnostics
    ins_left({
      "diagnostics",
      sources = { "nvim_diagnostic" },
      symbols = { error = " ", warn = " ", info = " " },
      diagnostics_color = {
        error = { fg = colors.red },
        warn = { fg = colors.yellow },
        info = { fg = colors.cyan },
      },
    })

    -- spacer to push remaining stuff to the right
    ins_left({
      function()
        return "%="
      end,
    })

    -- LSP client(s)
    ins_left({
      function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if not clients or next(clients) == nil then
          return "No Active LSP"
        end

        local names_seen = {}
        local names = {}
        for _, client in ipairs(clients) do
          if not names_seen[client.name] then
            table.insert(names, client.name)
            names_seen[client.name] = true
          end
        end
        return table.concat(names, ", ")
      end,
      icon = "󱍔 LSP:",
      color = { fg = colors.yellow, gui = "bold" },
    })

    -- Formatter(s)
    ins_left({
      function()
        local ok, conform = pcall(require, "conform")
        if not ok then
          return ""
        end
        local buf = vim.api.nvim_get_current_buf()
        local formatters = conform.list_formatters_to_run(buf)
        if not formatters or vim.tbl_isempty(formatters) then
          return ""
        end
        local names = vim.tbl_map(function(f)
          return f.name
        end, formatters)
        return table.concat(names, ", ")
      end,
      icon = "󰁨 ",
      color = { fg = colors.magenta, gui = "bold" },
    })

    -- Linter(s)
    ins_left({
      function()
        local ok, lint = pcall(require, "lint")
        if not ok then
          return ""
        end

        local buf = vim.api.nvim_get_current_buf()
        local ft = vim.bo[buf].filetype
        local configured = lint.linters_by_ft[ft]
        if not configured or vim.tbl_isempty(configured) then
          return ""
        end

        return table.concat(configured, ", ")
      end,
      icon = " ",
      color = { fg = colors.orange, gui = "bold" },
    })

    ---------------------------------------------------------------------------
    -- RIGHT side
    ---------------------------------------------------------------------------

    ins_right({
      "o:encoding",
      fmt = string.upper,
      cond = conditions.hide_in_width,
      color = { fg = colors.green, gui = "bold" },
    })

    ins_right({
      "fileformat",
      fmt = string.upper,
      icons_enabled = false,
      color = { fg = colors.green, gui = "bold" },
    })

    ins_right({
      "branch",
      icon = "",
      color = { fg = colors.cyan, gui = "bold" },
      cond = conditions.check_git_workspace,
    })

    ins_right({
      "diff",
      symbols = { added = "󰐖 ", modified = "󰦓 ", removed = "󰍵 " },
      diff_color = {
        added = { fg = colors.green },
        modified = { fg = colors.orange },
        removed = { fg = colors.red },
      },
      cond = conditions.hide_in_width,
    })

    ---------------------------------------------------------------------------
    -- go live
    ---------------------------------------------------------------------------
    lualine.setup(config)
  end,
}
