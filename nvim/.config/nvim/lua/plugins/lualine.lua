return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}
    opts.sections = opts.sections or {}
    opts.sections.lualine_c = opts.sections.lualine_c or {}
    opts.sections.lualine_x = opts.sections.lualine_x or {}

    opts.options.theme = "catppuccin"

    -- Add %S to lualine_c
    table.insert(opts.sections.lualine_c, "%S")

    -- Trouble statusline integration (safe)
    local ok_trouble, trouble = pcall(require, "trouble")
    if ok_trouble and trouble.statusline then
      local symbols = trouble.statusline({
        mode = "lsp_document_symbols",
        groups = {},
        title = false,
        filter = { range = true },
        format = "{kind_icon}{symbol.name:Normal}",
        hl_group = "lualine_c_normal",
      })

      table.insert(opts.sections.lualine_c, {
        symbols.get,
        cond = symbols.has,
      })
    end

    -- Noice mode indicator (safe)
    local ok_noice, noice = pcall(require, "noice")
    if ok_noice and noice.api and noice.api.status.mode then
      table.insert(opts.sections.lualine_x, {
        noice.api.status.mode.get,
        cond = noice.api.status.mode.has,
      })
    end
  end,
}
