--- Module for dynamically setting LSP-related keymaps based on attached client capabilities.
local M = {}

local helpers = require("user.helpers") -- Use centralized helpers for notifications.

--- Configuration for LSP function keymaps.
M.lsp_function_to_keymap_config = {
  definition     = { "n", "gd", "Go to Definition", vim.lsp.buf.definition },
  declaration    = { "n", "gD", "Go to Declaration", vim.lsp.buf.declaration },
  hover          = { "n", "K", "Hover Documentation", vim.lsp.buf.hover },
  implementation = { "n", "gI", "Go to Implementation", vim.lsp.buf.implementation },
  references     = { "n", "gr", "Go to References", vim.lsp.buf.references },
  rename         = { "n", "<leader>lr", "Rename", vim.lsp.buf.rename },
  code_action    = { { "n", "v" }, "<leader>la", "Code Action", vim.lsp.buf.code_action },
  format         = { "n", "<leader>lf", "Format", function() vim.lsp.buf.format({ async = true }) end },
}

--- Maps LSP functions to their respective server capabilities.
M.lsp_function_to_provider = {
  hover = "hoverProvider",
  definition = "definitionProvider",
  type_definition = "typeDefinitionProvider",
  implementation = "implementationProvider",
  declaration = "declarationProvider",
  references = "referencesProvider",
  rename = "renameProvider",
  code_action = "codeActionProvider",
  format = "documentFormattingProvider",
  range_formatting = "documentRangeFormattingProvider",
  signature_help = "signatureHelpProvider",
  document_symbol = "documentSymbolProvider",
  workspace_symbol = "workspaceSymbolProvider",
  document_highlight = "documentHighlightProvider",
  incoming_calls = "callHierarchyProvider",
  outgoing_calls = "callHierarchyProvider",
  semantic_tokens_full = "semanticTokensProvider.full",
  semantic_tokens_range = "semanticTokensProvider.range",
  folding_range = "foldingRangeProvider",
  code_lens = "codeLensProvider",
  execute_command = "executeCommandProvider",
}

--- Checks if any LSP client attached to the buffer supports a specific capability.
--- Logs the name of the client providing the feature when in debug mode.
--- @param feature string: The server capability to check (e.g., "hoverProvider").
--- @param bufnr number|nil: The buffer number. If nil, uses the current buffer.
--- @return boolean: True if at least one client supports the capability, false otherwise.
function M.check_all_clients(feature, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    helpers.notify("No LSP clients attached to buffer: " .. bufnr, vim.log.levels.WARN)
    return false
  end

  for _, client in ipairs(clients) do
    if client.server_capabilities[feature] then
      helpers.notify("Feature " .. feature .. " provided by: " .. client.name, vim.log.levels.DEBUG, true)
      return true -- Exit early if one client supports the feature.
    end
  end

  helpers.notify("No clients support " .. feature .. ".", vim.log.levels.WARN, true)
  return false
end

--- Dynamically sets keymaps for LSP features based on client capabilities.
--- Keymaps are only set if at least one attached LSP client supports the feature.
--- @param bufnr number: The buffer number to set the keymaps for.
function M.set_dynamic_lsp_keymaps(bufnr)
  for lsp_function, keymap_config in pairs(M.lsp_function_to_keymap_config) do
    -- Retrieve the corresponding LSP capability for the function.
    local feature = M.lsp_function_to_provider[lsp_function]

    if not feature then
      helpers.notify("No provider mapping for function: " .. lsp_function, vim.log.levels.ERROR)
    else
      -- Check if any LSP client attached to the buffer supports this feature.
      local has_feature = M.check_all_clients(feature, bufnr)
      if has_feature then
        -- Use vim.keymap.set to dynamically bind the action.
        vim.keymap.set(
          keymap_config[1],          -- Modes
          keymap_config[2],          -- Keybinding
          keymap_config[4],          -- Action
          {
            desc = keymap_config[3], -- Description for better user feedback.
            noremap = true,          -- Prevent recursive mappings.
            silent = true,           -- Suppress command echo.
            buffer = bufnr,          -- Scope the keymap to the current buffer.
          }
        )
        helpers.notify("Set keymap: " .. keymap_config[2] .. " for " .. lsp_function, vim.log.levels.DEBUG, true)
      else
        helpers.notify("Skipping keymap for " .. lsp_function .. ": feature not supported.", vim.log.levels.DEBUG, true)
      end
    end
  end
end

--- Sets all LSP-related keymaps for the specified buffer.
--- Combines dynamic keymaps (based on client capabilities) with always-set keymaps.
--- @param bufnr number: The buffer number to set the keymaps for.
function M.set_all_lsp_keymaps(bufnr)
  M.set_dynamic_lsp_keymaps(bufnr)

  -- Always set the following keymap regardless of client capabilities.
  vim.keymap.set("n", "gl", vim.diagnostic.open_float, {
    desc = "Go to Line Diagnostics",
    noremap = true,
    silent = true,
    buffer = bufnr,
  })
  helpers.notify("Set keymap: gl for Line Diagnostics", vim.log.levels.DEBUG, true)
end

return M

