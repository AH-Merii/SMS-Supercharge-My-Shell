-- lua/config/lsp-extras.lua
local M = {}

-- ============================================================================
-- Helpers (DRY)
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

local function get_key_features(caps)
  local features = {}
  if caps.completionProvider then table.insert(features, "completion") end
  if caps.hoverProvider then table.insert(features, "hover") end
  if caps.definitionProvider then table.insert(features, "definition") end
  if caps.referencesProvider then table.insert(features, "references") end
  if caps.renameProvider then table.insert(features, "rename") end
  if caps.codeActionProvider then table.insert(features, "code_action") end
  if caps.documentFormattingProvider then table.insert(features, "formatting") end
  return features
end

local function print_client_basic_info(i, client)
  print(string.format("󰌘 Client %d: %s", i, client.name))
  print("  ID: " .. client.id)
  print("  Root dir: " .. (client.config.root_dir or "Not set"))
  print("  Filetypes: " .. table.concat(client.config.filetypes or {}, ", "))
end

local function print_diagnostics_summary(bufnr)
  local counts, total = count_diagnostics(bufnr)
  local sev = vim.diagnostic.severity

  if total > 0 then
    print("󰒡 Diagnostics Summary:")
    print("  󰅚 Errors: " .. counts[sev.ERROR])
    print("  󰀪 Warnings: " .. counts[sev.WARN])
    print("  󰋽 Info: " .. counts[sev.INFO])
    print("  󰌶 Hints: " .. counts[sev.HINT])
    print("  Total: " .. total)
  else
    print("󰄬 No diagnostics")
  end
end

-- ============================================================================
-- Commands
-- ============================================================================

-- Quick status view - client info + key features
function M.lsp_status()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = get_clients(bufnr)

  if #clients == 0 then
    print("󰅚 No LSP clients attached")
    return
  end

  print("󱍔 Status for buffer " .. bufnr .. ":")
  print("─────────────────────────────────")

  for i, client in ipairs(clients) do
    print(string.format("󰌘 Client %d: %s (ID: %d)", i, client.name, client.id))
    print("  Root: " .. (client.config.root_dir or "N/A"))
    print("  Filetypes: " .. table.concat(client.config.filetypes or {}, ", "))

    local features = get_key_features(client.server_capabilities)
    print("  Features: " .. table.concat(features, ", "))
    print("")
  end
end

-- Comprehensive LSP information
function M.lsp_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = get_clients(bufnr)

  print("═══════════════════════════════════")
  print("           LSP INFORMATION          ")
  print("═══════════════════════════════════")
  print("")

  -- Basic info
  print("󰈙 Language client log: " .. vim.lsp.get_log_path())
  print("󰈔 Detected filetype: " .. vim.bo.filetype)
  print("󰈮 Buffer: " .. bufnr)
  print("󰈔 Root directory: " .. (vim.fn.getcwd() or "N/A"))
  print("")

  if #clients == 0 then
    print("󰅚 No LSP clients attached to buffer " .. bufnr)
    print("")
    print("Possible reasons:")
    print("  • No language server installed for " .. vim.bo.filetype)
    print("  • Language server not configured")
    print("  • Not in a project root directory")
    print("  • File type not recognized")
    return
  end

  print("󰒋 LSP clients attached to buffer " .. bufnr .. ":")
  print("─────────────────────────────────")

  for i, client in ipairs(clients) do
    print_client_basic_info(i, client)
    print("  Command: " .. table.concat(client.config.cmd or {}, " "))

    -- Server status
    if client.is_stopped() then
      print("  Status: 󰅚 Stopped")
    else
      print("  Status: 󰄬 Running")
    end

    -- Workspace folders
    if client.workspace_folders and #client.workspace_folders > 0 then
      print("  Workspace folders:")
      for _, folder in ipairs(client.workspace_folders) do
        print("    • " .. folder.name)
      end
    end

    -- Attached buffers count
    local attached_buffers = {}
    for buf, _ in pairs(client.attached_buffers or {}) do
      table.insert(attached_buffers, buf)
    end
    print("  Attached buffers: " .. #attached_buffers)

    -- Key capabilities
    local key_features = get_key_features(client.server_capabilities)
    if #key_features > 0 then
      print("  Key features: " .. table.concat(key_features, ", "))
    end

    print("")
  end

  -- Diagnostics summary
  print_diagnostics_summary(bufnr)
  print("")
  print("Use :LspLog to view detailed logs")
  print("Use :LspCapabilities for full capability list")
end

-- Full capability inspection
function M.lsp_capabilities()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = get_clients(bufnr)

  if #clients == 0 then
    print("No LSP clients attached")
    return
  end

  for _, client in ipairs(clients) do
    print("═══════════════════════════════════")
    print("  Capabilities: " .. client.name)
    print("═══════════════════════════════════")
    print("")

    local caps = client.server_capabilities

    -- Grouped by category for better readability
    local categories = {
      ["Navigation"] = {
        { "Go to Definition",      caps.definitionProvider },
        { "Go to Declaration",     caps.declarationProvider },
        { "Go to Implementation",  caps.implementationProvider },
        { "Go to Type Definition", caps.typeDefinitionProvider },
        { "Find References",       caps.referencesProvider },
      },
      ["Code Intelligence"] = {
        { "Completion",         caps.completionProvider },
        { "Hover",              caps.hoverProvider },
        { "Signature Help",     caps.signatureHelpProvider },
        { "Document Symbol",    caps.documentSymbolProvider },
        { "Workspace Symbol",   caps.workspaceSymbolProvider },
        { "Document Highlight", caps.documentHighlightProvider },
      },
      ["Editing"] = {
        { "Rename",      caps.renameProvider },
        { "Code Action", caps.codeActionProvider },
        { "Code Lens",   caps.codeLensProvider },
      },
      ["Formatting"] = {
        { "Document Formatting",       caps.documentFormattingProvider },
        { "Document Range Formatting", caps.documentRangeFormattingProvider },
      },
      ["Other"] = {
        { "Folding Range",   caps.foldingRangeProvider },
        { "Selection Range", caps.selectionRangeProvider },
      },
    }

    for category, items in pairs(categories) do
      print(category .. ":")
      for _, item in ipairs(items) do
        local icon = item[2] and "✓" or "✗"
        print(string.format("  %s %s", icon, item[1]))
      end
      print("")
    end
  end
end

-- Just diagnostics
function M.lsp_diagnostics()
  local counts, total = count_diagnostics()
  local sev = vim.diagnostic.severity

  print("󰒡 Diagnostics for current buffer:")
  print("  Errors: " .. counts[sev.ERROR])
  print("  Warnings: " .. counts[sev.WARN])
  print("  Info: " .. counts[sev.INFO])
  print("  Hints: " .. counts[sev.HINT])
  print("  Total: " .. total)
end

-- Full tooling status (LSP + formatters + linters + treesitter)
function M.status()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  print(string.format("Buffer Status for %s", ft))
  print("─────────────────────────")

  -- LSP
  local clients = get_clients(bufnr)
  local client_names = vim.tbl_map(function(c) return c.name end, clients)
  print(string.format("󱍔  LSP: %s", next(client_names) and table.concat(client_names, ", ") or "none"))

  -- Formatters
  local ok, conform = pcall(require, "conform")
  if ok then
    local formatters = conform.list_formatters_to_run(bufnr)
    local names = vim.tbl_map(function(f) return f.name end, formatters)
    print(string.format("󰁨  Formatters: %s", next(names) and table.concat(names, ", ") or "none"))
  else
    print("󰁨  Formatters: none")
  end

  -- Linters
  local ok_lint, lint = pcall(require, "lint")
  if ok_lint then
    local linters = lint.linters_by_ft[ft] or {}
    print(string.format("󱉶  Linters: %s", next(linters) and table.concat(linters, ", ") or "none"))
  else
    print("󱉶  Linters: none")
  end

  -- Diagnostics
  local counts = count_diagnostics(bufnr)
  local sev = vim.diagnostic.severity
  print(string.format(
    "  Diagnostics: %d err, %d warn, %d info, %d hint",
    counts[sev.ERROR],
    counts[sev.WARN],
    counts[sev.INFO],
    counts[sev.HINT]
  ))

  -- Treesitter
  local has_parser = pcall(vim.treesitter.get_parser, bufnr)
  print(string.format("  Treesitter: %s", has_parser and "enabled" or "none"))
end

-- ============================================================================
-- Register Commands
-- ============================================================================

vim.api.nvim_create_user_command('LspStatus', M.lsp_status, { desc = "Quick LSP status" })
vim.api.nvim_create_user_command('LspInfo', M.lsp_info, { desc = "Comprehensive LSP information" })
vim.api.nvim_create_user_command('LspCapabilities', M.lsp_capabilities, { desc = "Detailed capability list" })
vim.api.nvim_create_user_command('LspDiagnostics', M.lsp_diagnostics, { desc = "Diagnostics summary" })
vim.api.nvim_create_user_command('Status', M.status, { desc = "Full tooling status" })

return M
