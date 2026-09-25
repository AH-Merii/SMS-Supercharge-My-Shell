local M = {}

function M.setup()
  local autocmd = vim.api.nvim_create_autocmd
  local augroup = vim.api.nvim_create_augroup
  local user_group = augroup("UserAutocmds", { clear = true })

  -- Utility to sanitize and normalize command results
  local function sanitize_system_result(result)
    local _ = {}
    -- ok is true if exit code == 0 (success)
    _.ok = (result.code or 0) == 0
    _.stderr = (result.stderr or ""):gsub("%s+$", "")
    _.stdout = (result.stdout or ""):gsub("%s+$", "")
    _.output = _.stderr ~= "" and _.stderr or _.stdout
    if _.output == "" then
      _.output = "No output from ghostty command"
    end
    return _
  end

  -- Validate Ghostty config
  local function validate_ghostty_config()
    if vim.fn.executable("ghostty") ~= 1 then
      return
    end

    local validate = sanitize_system_result(vim.system({ "ghostty", "+validate-config" }, { text = true }):wait())

    if not validate.ok then
      vim.notify("󰧵  Invalid Ghostty config:\n" .. validate.output, vim.log.levels.WARN, { title = "Ghostty" })
      return false
    end

    return true
  end

  -- Reload Ghostty config (future CLI command)
  local function reload_ghostty_config()
    if vim.fn.executable("ghostty") ~= 1 then
      return
    end

    -- TODO Ghostty does not currently expose reload-config via the api, this is a placeholder function
    -- I need to replace '+reload-config' with the appropriate endpoint once it is supported
    local reload = sanitize_system_result(vim.system({ "ghostty", "+reload-config" }, { text = true }):wait())

    if not reload.ok then
      vim.notify("󰧵  Failed to reload Ghostty config:\n" .. reload.output, vim.log.levels.WARN, { title = "Ghostty" })
      return false
    end

    vim.notify("󰊠  Ghostty config reloaded!", vim.log.levels.INFO, { title = "Ghostty" })
    return true
  end

  -- Validate and optionally reload
  local function validate_and_reload_ghostty_config()
    -- Validate first
    if not validate_ghostty_config() then
      return
    end

    -- TODO: Reload (future CLI)
    -- reload_ghostty_config()
  end

  autocmd("BufWritePost", {
    group = user_group,
    pattern = {
      "*/ghostty/config",
    },
    callback = function() validate_and_reload_ghostty_config() end,
    desc = "Validate Ghostty config on save and reload if valid",
  })

  -- Disable automatic comment insertion on new lines
  autocmd("BufEnter", {
    group = user_group,
    callback = function() vim.opt.formatoptions:remove({ "c", "r", "o" }) end,
  })

  -- Wrap words softly in mail buffer
  autocmd("FileType", {
    group = user_group,
    pattern = "mail",
    callback = function()
      vim.opt_local.textwidth = 0
      vim.opt_local.wrapmargin = 0
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
      vim.opt_local.columns = 80
      vim.opt_local.colorcolumn = "80"
    end,
  })

  -- Highlight on yank
  autocmd("TextYankPost", {
    group = user_group,
    callback = function() vim.highlight.on_yank({ higroup = "Search", timeout = 200 }) end,
  })

  -- Close specific filetypes with 'q'
  autocmd("FileType", {
    group = user_group,
    pattern = {
      "PlenaryTestPopup",
      "help",
      "lspinfo",
      "man",
      "notify",
      "qf",
      "spectre_panel",
      "startuptime",
      "tsplayground",
      "neotest-output",
      "checkhealth",
      "neotest-summary",
      "neotest-output-panel",
      "netrw",
      "Jaq",
      "git",
      "oil",
      "lir",
    },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.keymap.set("n", "q", "<cmd>close<cr>", {
        buffer = event.buf,
        silent = true,
        desc = "Close window",
      })
    end,
  })

  -- Resize windows equally when Neovim is resized
  autocmd("VimResized", {
    group = user_group,
    callback = function() vim.cmd("tabdo wincmd =") end,
  })

  -- Show cursor line only in active window
  local cursor_group = augroup("CursorLine", { clear = true })
  autocmd({ "InsertLeave", "WinEnter" }, {
    group = cursor_group,
    callback = function() vim.opt_local.cursorline = true end,
  })
  autocmd({ "InsertEnter", "WinLeave" }, {
    group = cursor_group,
    callback = function() vim.opt_local.cursorline = false end,
  })

  -- Enable spell checking and wrapping for text-based files
  autocmd("FileType", {
    group = user_group,
    pattern = { "gitcommit", "oil", "markdown", "text", "tex", "NeogitCommitMessage", "typst" },
    callback = function()
      vim.opt_local.spell = true
      vim.opt_local.spelllang = "en"
      vim.opt_local.wrap = true
    end,
  })

  -- Fix terraform and HCL comment string
  autocmd("FileType", {
    group = user_group,
    pattern = { "terraform", "hcl" },
    callback = function(event) vim.bo[event.buf].commentstring = "# %s" end,
  })

  -- LuaSnip integration
  autocmd("CursorHold", {
    group = user_group,
    callback = function()
      local status_ok, luasnip = pcall(require, "luasnip")
      if not status_ok then
        return
      end
      if luasnip.expand_or_jumpable() then
        vim.cmd([[silent! lua require("luasnip").unlink_current()]])
      end
    end,
  })
end

return M
