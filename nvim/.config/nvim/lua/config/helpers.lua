local M = {}

-- ============================================================================
-- Helpers
-- ============================================================================

local function get_clients(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return vim.lsp.get_clients({ bufnr = bufnr })
end

local function count_diagnostics(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr)
  local sev = vim.diagnostic.severity

  local counts = {
    [sev.ERROR] = 0,
    [sev.WARN] = 0,
    [sev.INFO] = 0,
    [sev.HINT] = 0,
  }

  for _, diagnostic in ipairs(diagnostics) do
    counts[diagnostic.severity] = counts[diagnostic.severity] + 1
  end

  return counts, #diagnostics
end

---@param bufnr integer?
---@param header string?
---@return string[]
local function build_diagnostics_summary(bufnr, header)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  header = header or "󰒡 Diagnostics Summary:"

  local lines = {}
  local counts, total = count_diagnostics(bufnr)
  local sev = vim.diagnostic.severity

  if total > 0 then
    table.insert(lines, header)
    table.insert(lines, "   󰅚 Errors:   " .. counts[sev.ERROR])
    table.insert(lines, "   󰀪 Warnings: " .. counts[sev.WARN])
    table.insert(lines, "   󰋽 Info:     " .. counts[sev.INFO])
    table.insert(lines, "   󰌶 Hints:    " .. counts[sev.HINT])
    table.insert(lines, "    Total:    " .. total)
  else
    table.insert(lines, "󰄬 No diagnostics")
  end

  return lines
end

local function get_key_features(caps)
  local features = {}
  if caps.completionProvider then
    table.insert(features, "completion")
  end
  if caps.hoverProvider then
    table.insert(features, "hover")
  end
  if caps.definitionProvider then
    table.insert(features, "definition")
  end
  if caps.referencesProvider then
    table.insert(features, "references")
  end
  if caps.renameProvider then
    table.insert(features, "rename")
  end
  if caps.codeActionProvider then
    table.insert(features, "code_action")
  end
  if caps.documentFormattingProvider then
    table.insert(features, "formatting")
  end
  return features
end

---@param i integer
---@param client vim.lsp.Client
---@return string[]
local function build_client_basic_info(i, client)
  local lines = {}
  table.insert(lines, string.format("󰌘 Client %d: %s", i, client.name))
  table.insert(lines, "  ID: " .. client.id)
  table.insert(lines, "  Root dir: " .. (client.config.root_dir or "Not set"))
  table.insert(lines, "  Filetypes: " .. table.concat(client.config.filetypes or {}, ", "))
  return lines
end

---@param lines string[]
local function echo_lines(lines)
  for _, line in ipairs(lines) do
    print(line)
  end
end

-- ============================================================================
-- Builders
-- ============================================================================

---@return string[]
function M.build_lsp_status()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = get_clients(bufnr)
  local lines = {}

  if #clients == 0 then
    table.insert(lines, "󰅚 No LSP clients attached")
    return lines
  end

  table.insert(lines, "󱍔 Status for buffer " .. bufnr .. ":")
  table.insert(lines, "─────────────────────────────────")

  for i, client in ipairs(clients) do
    table.insert(lines, string.format("󰌘 Client %d: %s (ID: %d)", i, client.name, client.id))
    table.insert(lines, "  Root: " .. (client.config.root_dir or "N/A"))
    table.insert(lines, "  Filetypes: " .. table.concat(client.config.filetypes or {}, ", "))

    local features = get_key_features(client.server_capabilities)
    table.insert(lines, "  Features: " .. table.concat(features, ", "))
    table.insert(lines, "")
  end

  return lines
end

---@return string[]
function M.build_lsp_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = get_clients(bufnr)

  local lines = {}
  table.insert(lines, "═══════════════════════════════════")
  table.insert(lines, "           LSP INFORMATION          ")
  table.insert(lines, "═══════════════════════════════════")
  table.insert(lines, "")

  -- Basic info
  table.insert(lines, "󰈙 Language client log: " .. vim.lsp.get_log_path())
  table.insert(lines, "󰈔 Detected filetype: " .. vim.bo.filetype)
  table.insert(lines, "󰈮 Buffer: " .. bufnr)
  table.insert(lines, "󰈔 Root directory: " .. (vim.fn.getcwd() or "N/A"))
  table.insert(lines, "")

  if #clients == 0 then
    table.insert(lines, "󰅚 No LSP clients attached to buffer " .. bufnr)
    table.insert(lines, "")
    table.insert(lines, "Possible reasons:")
    table.insert(lines, "  • No language server installed for " .. vim.bo.filetype)
    table.insert(lines, "  • Language server not configured")
    table.insert(lines, "  • Not in a project root directory")
    table.insert(lines, "  • File type not recognized")
    return lines
  end

  table.insert(lines, "󱍔 LSP clients attached to buffer " .. bufnr .. ":")
  table.insert(lines, "─────────────────────────────────")

  for i, client in ipairs(clients) do
    vim.list_extend(lines, build_client_basic_info(i, client))
    table.insert(lines, "  Command: " .. table.concat(client.config.cmd or {}, " "))

    -- Server status
    if client.is_stopped() then
      table.insert(lines, "  Status: 󰅚 Stopped")
    else
      table.insert(lines, "  Status: 󰄬 Running")
    end

    -- Workspace folders
    if client.workspace_folders and #client.workspace_folders > 0 then
      table.insert(lines, "  Workspace folders:")
      for _, folder in ipairs(client.workspace_folders) do
        table.insert(lines, "    • " .. folder.name)
      end
    end

    -- Attached buffers
    local attached_buffers = {}
    for buf, _ in pairs(client.attached_buffers or {}) do
      table.insert(attached_buffers, buf)
    end
    table.insert(lines, "  Attached buffers: " .. #attached_buffers)

    -- Key capabilities
    local key_features = get_key_features(client.server_capabilities)
    if #key_features > 0 then
      table.insert(lines, "  Key features: " .. table.concat(key_features, ", "))
    end

    table.insert(lines, "")
  end

  -- Diagnostics summary
  vim.list_extend(lines, build_diagnostics_summary(bufnr))
  table.insert(lines, "")
  table.insert(lines, "Use :LspLog to view detailed logs")
  table.insert(lines, "Use :LspCapabilities for full capability list")

  return lines
end

---@return string[]
function M.build_lsp_capabilities()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = get_clients(bufnr)
  local lines = {}

  if #clients == 0 then
    table.insert(lines, "No LSP clients attached")
    return lines
  end

  for _, client in ipairs(clients) do
    table.insert(lines, "═══════════════════════════════════")
    table.insert(lines, "  Capabilities: " .. client.name)
    table.insert(lines, "═══════════════════════════════════")
    table.insert(lines, "")

    local caps = client.server_capabilities

    local categories = {
      ["Navigation"] = {
        { "Go to Definition", caps.definitionProvider },
        { "Go to Declaration", caps.declarationProvider },
        { "Go to Implementation", caps.implementationProvider },
        { "Go to Type Definition", caps.typeDefinitionProvider },
        { "Find References", caps.referencesProvider },
      },
      ["Code Intelligence"] = {
        { "Completion", caps.completionProvider },
        { "Hover", caps.hoverProvider },
        { "Signature Help", caps.signatureHelpProvider },
        { "Document Symbol", caps.documentSymbolProvider },
        { "Workspace Symbol", caps.workspaceSymbolProvider },
        { "Document Highlight", caps.documentHighlightProvider },
      },
      ["Editing"] = {
        { "Rename", caps.renameProvider },
        { "Code Action", caps.codeActionProvider },
        { "Code Lens", caps.codeLensProvider },
      },
      ["Formatting"] = {
        { "Document Formatting", caps.documentFormattingProvider },
        { "Document Range Formatting", caps.documentRangeFormattingProvider },
      },
      ["Other"] = {
        { "Folding Range", caps.foldingRangeProvider },
        { "Selection Range", caps.selectionRangeProvider },
      },
    }

    for category, items in pairs(categories) do
      table.insert(lines, category .. ":")
      for _, item in ipairs(items) do
        local icon = item[2] and "✓" or "✗"
        table.insert(lines, string.format("  %s %s", icon, item[1]))
      end
      table.insert(lines, "")
    end
  end

  return lines
end

---@return string[]
function M.build_lsp_diagnostics() return build_diagnostics_summary(nil, "󰒡 Diagnostics for current buffer:") end

---@return string[]
function M.build_status()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  local lines = {}
  table.insert(lines, string.format("Buffer Status for %s", ft))
  table.insert(lines, "─────────────────────────")

  -- LSP
  local clients = get_clients(bufnr)
  local client_names = vim.tbl_map(function(c) return c.name end, clients)
  table.insert(lines, string.format("󱍔  LSP: %s", next(client_names) and table.concat(client_names, ", ") or "none"))

  -- Formatters
  local ok_conform, conform = pcall(require, "conform")
  if ok_conform then
    local formatters = conform.list_formatters_to_run(bufnr)
    local names = vim.tbl_map(function(f) return f.name end, formatters)
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

  -- Treesitter
  local has_parser = pcall(vim.treesitter.get_parser, bufnr)
  table.insert(lines, string.format("  Treesitter: %s", has_parser and "enabled" or "none"))
  table.insert(lines, "")

  -- Diagnostics block
  vim.list_extend(lines, build_diagnostics_summary(bufnr))

  return lines
end

-- ============================================================================
-- Public user-facing commands
-- ============================================================================

function M.lsp_status() echo_lines(M.build_lsp_status()) end

function M.lsp_info() echo_lines(M.build_lsp_info()) end

function M.lsp_capabilities() echo_lines(M.build_lsp_capabilities()) end

function M.lsp_diagnostics() echo_lines(M.build_lsp_diagnostics()) end

function M.status() echo_lines(M.build_status()) end

-- ============================================================================
-- Register Commands
-- ============================================================================

vim.api.nvim_create_user_command("LspStatus", M.lsp_status, { desc = "Quick LSP status" })
vim.api.nvim_create_user_command("LspInfo", M.lsp_info, { desc = "Comprehensive LSP information" })
vim.api.nvim_create_user_command("LspCapabilities", M.lsp_capabilities, { desc = "Detailed capability list" })
vim.api.nvim_create_user_command("LspDiagnostics", M.lsp_diagnostics, { desc = "Diagnostics summary" })
vim.api.nvim_create_user_command("Status", M.status, { desc = "Full tooling status" })

return M
