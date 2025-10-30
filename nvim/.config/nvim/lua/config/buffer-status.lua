-- lua/config/status.lua
local M = {}

---@param bufnr integer?
---@return string[]
function M.get_status_lines(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  local lines = {
    string.format("Buffer Status for %s", ft),
    "─────────────────────────",
  }

  -- LSP
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local client_names = vim.tbl_map(function(c)
    return c.name
  end, clients)
  table.insert(lines, string.format("󱍔  LSP: %s", next(client_names) and table.concat(client_names, ", ") or "none"))

  -- Formatters
  local ok, conform = pcall(require, "conform")
  if ok then
    local formatters = conform.list_formatters_to_run(bufnr)
    local names = vim.tbl_map(function(f)
      return f.name
    end, formatters)
    table.insert(lines, string.format("󰁨  Formatters: %s", next(names) and table.concat(names, ", ") or "none"))
  else
    table.insert(lines, "󰁨  Formatters: none")
  end

  -- Linters
  local ok_lint, lint = pcall(require, "lint")
  if ok_lint then
    local linters = lint.linters_by_ft[ft] or {}
    table.insert(lines, string.format("󱉶  Linters: %s", next(linters) and table.concat(linters, ", ") or "none"))
  else
    table.insert(lines, "󱉶  Linters: none")
  end

  -- Diagnostics
  local diag = vim.diagnostic.count(bufnr)
  table.insert(lines, string.format(
    "  Diagnostics: %d err, %d warn, %d info, %d hint",
    diag[vim.diagnostic.severity.ERROR] or 0,
    diag[vim.diagnostic.severity.WARN] or 0,
    diag[vim.diagnostic.severity.INFO] or 0,
    diag[vim.diagnostic.severity.HINT] or 0
  ))

  -- Treesitter
  local has_parser = pcall(vim.treesitter.get_parser, bufnr)
  table.insert(lines, string.format("  Treesitter: %s", has_parser and "enabled" or "none"))

  return lines
end

function M.show()
  print(table.concat(M.get_status_lines(), "\n"))
end

vim.api.nvim_create_user_command("Status", M.show, {})

local wk_ok, wk = pcall(require, "whichkey")
if wk_ok then
  wk.add(
    { "<leader>l", group = "Git (Actions)", icon = { icon = "", color = "cyan" } }
  )
end


return M
