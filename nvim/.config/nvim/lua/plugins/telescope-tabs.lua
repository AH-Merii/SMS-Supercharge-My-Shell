local M = {
  "LukasPietzschmann/telescope-tabs",
  event = "VeryLazy",
}

function M.config()
  require("telescope-tabs").setup {
    show_preview = true,
    close_tab_shortcut_i = "<C-d>", -- if you're in insert mode
    close_tab_shortcut_n = "dd", -- if you're in normal mode
    entry_formatter = function(tab_id, file_names, is_current)
      local entry_string = table.concat(file_names, ", ")
      return string.format("%d: %s%s", tab_id, entry_string, is_current and " " or "")
    end,
  }
end

return M
