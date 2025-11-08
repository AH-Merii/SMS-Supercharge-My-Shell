local M = {}

function M.setup()
  local autocmd = vim.api.nvim_create_autocmd
  local augroup = vim.api.nvim_create_augroup

  local user_group = augroup("UserAutocmds", { clear = true })

  -- Save view (including folds) when leaving or writing the buffer
  autocmd({ "BufWinLeave", "BufWritePost" }, {
    group = user_group,
    desc = "Save view (folds, etc.)",
    callback = function(event)
      local buf = event.buf

      -- skip special/unnamed buffers
      if vim.bo[buf].buftype ~= "" then
        return
      end
      if vim.api.nvim_buf_get_name(buf) == "" then
        return
      end

      pcall(vim.api.nvim_command, "silent! mkview")
    end,
  })

  -- Restore view *after* reading the file, but DO NOT let it move the cursor.
  -- We:
  --   1. Wait for Snacks / LSP / etc. to finish their jumps (vim.schedule)
  --   2. Capture the current cursor position
  --   3. run :loadview (restores folds & window view)
  --   4. put the cursor back where it was
  autocmd("BufReadPost", {
    group = user_group,
    desc = "Load view (folds, keep cursor)",
    callback = function(event)
      local buf = event.buf

      -- skip special/unnamed buffers
      if vim.bo[buf].buftype ~= "" then
        return
      end
      if vim.api.nvim_buf_get_name(buf) == "" then
        return
      end

      vim.schedule(function()
        -- Find a window showing this buffer
        local win = vim.fn.bufwinid(buf)
        if win == -1 then
          return
        end

        -- Whatever put us here (Snacks, LSP, quickfix, plain open),
        -- this is the position we want to keep.
        local ok_pos, cur = pcall(vim.api.nvim_win_get_cursor, win)
        if not ok_pos then
          return
        end

        -- Restore view (folds, etc.)
        local ok = pcall(vim.api.nvim_command, "silent! loadview")
        if not ok then
          return
        end

        -- Put cursor back where it was before loadview
        pcall(vim.api.nvim_win_set_cursor, win, cur)
      end)
    end,
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
