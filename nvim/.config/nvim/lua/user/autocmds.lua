local M = {}

--- Setup function to initialize all autocmds.
--- This function sets up various Neovim autocommands for common use cases.
--- @return nil
function M.setup()
  local autocmd = vim.api.nvim_create_autocmd
  local augroup = vim.api.nvim_create_augroup

  -- Create a custom group for user-defined autocmds
  local user_group = augroup("UserAutocmds", { clear = true })

  -- Disable automatic comment insertion on new lines when entering a buffer window
  autocmd("BufWinEnter", {
    group = user_group,
    callback = function()
      vim.cmd("set formatoptions-=cro")
    end,
  })

  -- Set up specific behaviors for certain file types
  autocmd("FileType", {
    group = user_group,
    pattern = {
      "netrw", "Jaq", "qf", "git", "help", "man", "lspinfo",
      "oil", "spectre_panel", "lir", "DressingSelect",
      "tsplayground", "",
    },
    callback = function()
      vim.cmd([[
        nnoremap <silent> <buffer> q :close<CR>
        set nobuflisted
      ]])
    end,
  })

  -- Automatically quit Neovim when entering the command-line window
  autocmd("CmdWinEnter", {
    group = user_group,
    callback = function()
      vim.cmd("quit")
    end,
  })

  -- Resize all windows equally across tabs when Neovim is resized
  autocmd("VimResized", {
    group = user_group,
    callback = function()
      vim.cmd("tabdo wincmd =")
    end,
  })

  -- Check for changes to the file when entering a buffer window and reload if necessary
  autocmd("BufWinEnter", {
    group = user_group,
    pattern = { "*" },
    callback = function()
      vim.cmd("checktime")
    end,
  })

  -- Highlight yanked (copied) text briefly for visual feedback
  autocmd("TextYankPost", {
    group = user_group,
    callback = function()
      vim.highlight.on_yank({ higroup = "Visual", timeout = 40 })
    end,
  })

  -- Format the file before saving it, using specific LSP clients like efm or null-ls
  autocmd("BufWritePre", {
    group = user_group,
    pattern = "*",
    callback = function()
      vim.lsp.buf.format({ async = false })
    end,
  })

  -- Enable line wrapping and spell checking for specific file types
  autocmd("FileType", {
    group = user_group,
    pattern = { "gitcommit", "markdown", "NeogitCommitMessage" },
    callback = function()
      vim.opt_local.wrap = true  -- Enable line wrap
      vim.opt_local.spell = true -- Enable spell check
    end,
  })

  -- Automatically unlink the current snippet in LuaSnip when cursor is held over it
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
