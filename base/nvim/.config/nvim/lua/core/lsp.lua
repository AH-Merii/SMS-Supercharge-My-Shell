-- LSP servers are automatically managed by Mason
vim.diagnostic.config({
  virtual_text = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
})

local M = {}

---@class core.lsp.Key: vim.keymap.set.Opts
---@field [1] string lhs
---@field [2]? string|fun() rhs, or nil until a Snacks toggle supplies it through M.map
---@field mode? string
---@field method? string|string[] the buffer gets the map while an attached client supports any of these
---@field when? fun(buf: integer, clients: vim.lsp.Client[]): boolean the buffer also gets the map while this holds

-- A formatter set for the filetype in conform counts before its tool is installed
---@param buf integer
local function has_formatter(buf)
  local by_ft = require("conform").formatters_by_ft
  local ft = vim.bo[buf].filetype
  for _, name in ipairs(vim.list_extend({ ft, "_", "*" }, vim.split(ft, ".", { plain = true }))) do
    local formatters = by_ft[name]
    if type(formatters) == "function" or (type(formatters) == "table" and next(formatters)) then
      return true
    end
  end
  return false
end

local function format() require("conform").format_buffer({ async = true, quiet = false }) end

-- Diagnostics come from attached clients, and from nvim-lint where it has linters for the filetype
---@param buf integer
---@param clients vim.lsp.Client[]
local function has_diagnostics(buf, clients)
  if #clients > 0 then
    return true
  end
  local by_ft = require("lint").linters_by_ft
  local ft = vim.bo[buf].filetype
  for _, name in ipairs(vim.list_extend({ ft }, vim.split(ft, ".", { plain = true }))) do
    if next(by_ft[name] or {}) then
      return true
    end
  end
  return false
end

---@param clients vim.lsp.Client[]
local function has_pyrefly(_, clients)
  return vim.iter(clients):any(function(client) return client.name == "pyrefly" end)
end

---@type core.lsp.Key[]
M.keys = {
  { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Definition", method = "textDocument/definition" },
  { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Declaration", method = "textDocument/declaration" },
  { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Implementations", method = "textDocument/implementation" },
  { "grr", function() Snacks.picker.lsp_references() end, desc = "References", method = "textDocument/references" },
  { "gt", function() Snacks.picker.lsp_type_definitions() end, desc = "Type Definition", method = "textDocument/typeDefinition" },
  { "gCi", function() Snacks.picker.lsp_incoming_calls() end, desc = "Incoming Calls", method = "textDocument/prepareCallHierarchy" },
  { "gCo", function() Snacks.picker.lsp_outgoing_calls() end, desc = "Outgoing Calls", method = "textDocument/prepareCallHierarchy" },
  { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Reference (word)", method = "textDocument/documentHighlight" },
  { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Reference (word)", method = "textDocument/documentHighlight" },
  { "<leader>lr", function() vim.lsp.buf.rename() end, desc = "LSP Rename", method = "textDocument/rename" },
  { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)", method = "textDocument/documentSymbol" },
  {
    "<leader>cl",
    "<cmd>Trouble lsp toggle focus=false win.position=down<cr>",
    desc = "LSP Definitions / references / ... (Trouble)",
    method = {
      "textDocument/definition",
      "textDocument/references",
      "textDocument/implementation",
      "textDocument/typeDefinition",
      "textDocument/declaration",
      "textDocument/prepareCallHierarchy",
    },
  },
  { "<leader>Th", method = "textDocument/inlayHint" },
  { "<leader>Te", when = has_pyrefly },
  { "<leader>lf", format, desc = "Format buffer", method = "textDocument/formatting", when = has_formatter },
  { "<leader>lf", format, mode = "x", desc = "Format selection", method = "textDocument/rangeFormatting", when = has_formatter },
  { "<leader>Tf", method = "textDocument/formatting", when = has_formatter },
  { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)", when = has_diagnostics },
  { "<leader>sd", function() Snacks.picker.diagnostics_buffer() end, desc = "Diagnostics (Buffer)", when = has_diagnostics },
}

-- Neovim maps its LSP defaults globally; move them into the table so they are gated too
for _, builtin in ipairs({
  { "grn", "textDocument/rename" },
  { "gra", "textDocument/codeAction", desc = "Code action" },
  { "gri", "textDocument/implementation" },
  { "grt", "textDocument/typeDefinition" },
  { "grx", "textDocument/codeLens" },
  { "gO", "textDocument/documentSymbol" },
}) do
  local lhs, method = builtin[1], builtin[2]
  for _, mode in ipairs({ "n", "x" }) do
    local map = vim.fn.maparg(lhs, mode, false, true)
    if map.callback then
      vim.keymap.del(mode, lhs)
      table.insert(M.keys, { lhs, map.callback, mode = mode, desc = builtin.desc or map.desc, method = method })
    end
  end
end
pcall(vim.keymap.del, "n", "grr")

local not_opts = { mode = true, method = true, when = true }

---@param key core.lsp.Key
---@param buf integer
---@param clients vim.lsp.Client[]
local function supported(key, buf, clients)
  local methods = type(key.method) == "table" and key.method or { key.method }
  for _, client in ipairs(clients) do
    for _, method in ipairs(methods) do
      if client:supports_method(method, buf) then
        return true
      end
    end
  end
  return key.when ~= nil and key.when(buf, clients)
end

--- Adds or deletes each gated map in buf, leaving buffer-local maps of the same lhs from ftplugins alone.
---@param buf integer
---@param gone? integer id of a client that is detaching from buf
local function sync(buf, gone)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local clients = vim.tbl_filter(function(client) return client.id ~= gone end, vim.lsp.get_clients({ bufnr = buf }))
  for _, key in ipairs(M.keys) do
    if key[2] then
      local mode, lhs = key.mode or "n", vim.keycode(key[1])
      local held ---@type table?
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
        if map.lhsraw == lhs or map.lhsrawalt == lhs then
          held = map
        end
      end
      if supported(key, buf, clients) then
        if not held then
          local opts = { buf = buf }
          for k, v in pairs(key) do
            if type(k) == "string" and not not_opts[k] then
              opts[k] = v
            end
          end
          vim.keymap.set(mode, key[1], key[2], opts)
        end
      elseif held and held.desc == key.desc then
        vim.keymap.del(mode, key[1], { buf = buf })
      end
    end
  end
end

--- Supplies the rhs of a gated entry; pass it as Snacks.toggle's `map` so the toggle keeps its which-key label.
---@param mode string
---@param lhs string
---@param rhs string|fun()
---@param opts? vim.keymap.set.Opts
function M.map(mode, lhs, rhs, opts)
  for _, key in ipairs(M.keys) do
    if key[1] == lhs and (key.mode or "n") == mode then
      key[2], key.desc = rhs, opts and opts.desc
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        sync(buf)
      end
      return
    end
  end
  error(("core.lsp: no gated entry for %s %s"):format(mode, lhs))
end

local group = vim.api.nvim_create_augroup("core.lsp.keys", { clear = true })
vim.api.nvim_create_autocmd({ "FileType", "LspAttach" }, {
  group = group,
  callback = function(ev)
    -- Buffers vim.lsp.enable skips, like lazy's first-start install window, where requiring conform, even in a pcall, breaks the install
    if vim.bo[ev.buf].buftype ~= "" and vim.bo[ev.buf].buftype ~= "help" then
      return
    end
    vim.schedule(function() sync(ev.buf) end)
  end,
})
vim.api.nvim_create_autocmd("LspDetach", {
  group = group,
  callback = function(ev)
    local id = ev.data.client_id
    vim.schedule(function() sync(ev.buf, id) end)
  end,
})

-- Servers may (un)register methods after LspAttach, which fires no autocmd
for _, method in ipairs({ "client/registerCapability", "client/unregisterCapability" }) do
  local handler = vim.lsp.handlers[method]
  vim.lsp.handlers[method] = function(err, params, ctx)
    local result = handler(err, params, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client then
      vim.schedule(function()
        for buf in pairs(client.attached_buffers) do
          sync(buf)
        end
      end)
    end
    return result
  end
end

return M
