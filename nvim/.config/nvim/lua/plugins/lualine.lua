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
      buffer_not_empty = function() return vim.fn.empty(vim.fn.expand("%:t")) ~= 1 end,
      hide_in_width = function() return vim.fn.winwidth(0) > 80 end,
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
      local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(buf_dir) .. " rev-parse --show-toplevel")[1]
      if git_root and git_root ~= "" then
        return git_root
      end
      return vim.fn.getcwd()
    end

    ---------------------------------------------------------------------------
    -- Adaptive Path component with highlight
    ---------------------------------------------------------------------------
    --- Adaptive filepath component for lualine.
    --- Shows full path when space allows, then progressively shortens:
    ---   1. Abbreviate intermediate dirs (a/b/c)
    ---   2. Shorten project name (my..example)
    ---   3. Fallback to filename only
    ---
    --- @param component_width number? (0–1) fraction of total winwidth to use (default = 0.4)
    local function filepath_component(component_width)
      component_width = component_width or 0.4

      if vim.fn.bufname("%") == "" then
        return ""
      end

      local fullpath = vim.fn.expand("%:p")
      local root = get_project_root()
      if not fullpath or not root or fullpath == "" or root == "" then
        return vim.fn.expand("%:t")
      end

      local win_width = vim.fn.winwidth(0)
      local max_budget = math.floor(win_width * component_width)
      local rel = fullpath:gsub("^" .. vim.pesc(root) .. "/?", "")
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

      local function shorten_project_name(name)
        local words = {}
        for seg in name:gmatch("[^%-%_]+") do
          table.insert(words, seg)
        end
        if #words == 1 then
          for seg in name:gmatch("[A-Z][^A-Z]*") do
            table.insert(words, seg)
          end
        end
        if #words >= 2 then
          return words[1] .. ".." .. words[#words]
        end
        return name
      end

      local function build_path(proj, mid, file)
        local out = {}
        table.insert(out, hl_project .. proj .. hl_reset)
        if mid ~= "" then
          table.insert(out, "/" .. hl_middle .. mid .. hl_reset)
        end
        if file ~= "" then
          table.insert(out, "/" .. hl_file .. file .. hl_reset)
        end
        return table.concat(out, "")
      end

      local function path_width(str) return vim.fn.strdisplaywidth((str:gsub("%%#.-#", ""))) end

      local display = build_path(project_name, middle_path, filename)

      if path_width(display) > max_budget then
        local short_parts = {}
        for _, seg in ipairs(vim.list_slice(parts, 1, #parts - 1)) do
          table.insert(short_parts, seg:sub(1, 1))
        end
        middle_path = table.concat(short_parts, "/")
        display = build_path(project_name, middle_path, filename)
      end

      if path_width(display) > max_budget then
        project_name = shorten_project_name(project_name)
        display = build_path(project_name, middle_path, filename)
      end

      if path_width(display) > max_budget then
        display = hl_file .. filename .. hl_reset
      end

      return display
    end

    ---------------------------------------------------------------------------
    -- Highlight groups for statusline segments
    ---------------------------------------------------------------------------
    local function define_highlights()
      local set_hl = function(name, opts) vim.api.nvim_set_hl(0, name, opts) end
      set_hl("LualineNormal", { fg = colors.fg, bg = colors.bg })
      set_hl("LualineProjectRoot", { fg = colors.magenta, bg = colors.bg, bold = true })
      set_hl("LualinePath", { fg = colors.fg, bg = colors.bg })
      set_hl("LualineFilename", { fg = colors.blue, bg = colors.bg, bold = true })
    end

    define_highlights()

    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        colors = get_colors()
        define_highlights()
      end,
    })

    ---------------------------------------------------------------------------
    -- Macro recording component
    ---------------------------------------------------------------------------
    local function macro_recording()
      local reg = vim.fn.reg_recording()
      if reg == "" then
        return ""
      end
      return " @" .. reg
    end

    -- Refresh lualine when macro recording starts/stops
    vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
      callback = function() require("lualine").refresh() end,
    })

    ---------------------------------------------------------------------------
    -- lualine setup
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

    local function ins_left(component) table.insert(config.sections.lualine_c, component) end
    local function ins_right(component) table.insert(config.sections.lualine_x, component) end

    ---------------------------------------------------------------------------
    -- LEFT side
    ---------------------------------------------------------------------------
    ins_left({
      function() return "" end,
      color = function()
        local mode_color = {
          n = colors.fg,
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

    ins_left({
      function() return filepath_component(0.4) end,
      cond = conditions.buffer_not_empty,
    })

    ins_left({ "location" })
    ins_left({ "progress", color = { fg = colors.fg, gui = "bold" } })
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
    ins_left({ function() return "%=" end })

    ins_left({
      function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if not clients or next(clients) == nil then
          return "No Active LSP"
        end
        local names_seen, names = {}, {}
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
        local names = vim.tbl_map(function(f) return f.name end, formatters)
        return table.concat(names, ", ")
      end,
      icon = "󰁨 ",
      color = { fg = colors.magenta, gui = "bold" },
    })

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
    ins_right({
      macro_recording,
      color = { fg = colors.yellow, gui = "bold" },
    })

    ---------------------------------------------------------------------------
    -- go live
    ---------------------------------------------------------------------------
    lualine.setup(config)
  end,
}
