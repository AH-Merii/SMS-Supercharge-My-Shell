local M = {}

function M.setup()
  local autocmd = vim.api.nvim_create_autocmd
  local augroup = vim.api.nvim_create_augroup

  local user_group = augroup("UserAutocmds", { clear = true })

  -- Disable automatic comment insertion on new lines
  autocmd("BufEnter", {
    group = user_group,
    callback = function()
      vim.opt.formatoptions:remove({ "c", "r", "o" })
    end,
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
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = user_group,
    callback = function()
      vim.highlight.on_yank({ higroup = "Search", timeout = 200 })
    end,
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
    callback = function()
      vim.cmd("tabdo wincmd =")
    end,
  })

  -- Show cursor line only in active window
  local cursor_group = augroup("CursorLine", { clear = true })
  autocmd({ "InsertLeave", "WinEnter" }, {
    group = cursor_group,
    callback = function()
      vim.opt_local.cursorline = true
    end,
  })
  autocmd({ "InsertEnter", "WinLeave" }, {
    group = cursor_group,
    callback = function()
      vim.opt_local.cursorline = false
    end,
  })

  -- Enable spell checking and wrapping for text-based files
  autocmd("FileType", {
    group = user_group,
    pattern = { "gitcommit", "oil","markdown", "text", "tex", "NeogitCommitMessage", "typst" },
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
    callback = function(event)
      vim.bo[event.buf].commentstring = "# %s"
    end,
  })

  autocmd("LspAttach", {
  group = augroup("LspAttach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, {
        buffer = event.buf,
        desc = "LSP: " .. desc,
      })
    end

    map("gl", vim.diagnostic.open_float, "Open Diagnostic Float")
    map("K", vim.lsp.buf.hover, "Hover Documentation")
    map("gs", vim.lsp.buf.signature_help, "Signature Documentation")
    map("gD", vim.lsp.buf.declaration, "Declaration")
    map("gd", vim.lsp.buf.definition, "Definition")
    map("gv", function()
      vim.cmd("vsplit")
      vim.lsp.buf.definition()
    end, "Definition in Vertical Split")

    local status_ok, wk = pcall(require, "which-key")
    if status_ok then
      wk.add({
        { "<leader>la", vim.lsp.buf.code_action, desc = "Code Action" },
        { "<leader>ls", vim.lsp.buf.signature_help, desc = "Display Signature Information" },
        { "<leader>lr", vim.lsp.buf.rename, desc = "Rename all references" },
        { "<leader>lf", vim.lsp.buf.format, desc = "Format" },
        { "<leader>Wa", vim.lsp.buf.add_workspace_folder, desc = "Workspace Add Folder" },
        { "<leader>Wr", vim.lsp.buf.remove_workspace_folder, desc = "Workspace Remove Folder" },
        {
          "<leader>Wl",
          function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end,
          desc = "Workspace List Folders",
        },
      })
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)

    -- Document highlight
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local highlight_group = augroup("LspHighlight", { clear = false })

      autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        group = highlight_group,
        callback = vim.lsp.buf.document_highlight,
      })

      autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        group = highlight_group,
        callback = vim.lsp.buf.clear_references,
      })

      autocmd("LspDetach", {
        group = augroup("LspDetach", { clear = true }),
        callback = function(detach_event)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({
            group = "LspHighlight",
            buffer = detach_event.buf,
          })
        end,
      })
    end

    -- Inlay hints
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map("<leader>th", function()
        local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
      end, "Toggle Inlay Hints")
    end
  end,
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
