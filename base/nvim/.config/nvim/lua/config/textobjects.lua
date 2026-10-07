-- The treesitter text objects and moves: one global map per key, which runs the treesitter object where
-- its language has the capture and the key's own meaning everywhere else.
local M = {}
local ts = vim.treesitter

local selects = {} ---@type table<string, {query: string, desc: string}>
local moves = {} ---@type table<string, {fn: string, query: string, desc: string}>
local shadowed = {} ---@type table<string, table> mode .. lhs -> the global map the dispatcher took over
local mine = {} ---@type table<function, true>

---@param lang string
---@param query string a capture, "@function.outer"
local function has(lang, query)
  local q = ts.query.get(lang, "textobjects")
  return q ~= nil and vim.list_contains(q.captures, query:sub(2))
end

---@param buf integer
---@return vim.treesitter.LanguageTree?
local function parser_of(buf)
  local ok, parser = pcall(ts.get_parser, buf, nil, { error = false })
  return ok and parser or nil
end

--- The innermost language at the cursor that has text objects; markdown_inline is the prose of markdown
---@param buf integer
---@return vim.treesitter.LanguageTree?
local function cursor_tree(buf)
  local parser = parser_of(buf)
  if not parser then
    return
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  pcall(parser.parse, parser, { row - 1, row })
  local tree = parser:language_for_range({ row - 1, col, row - 1, col })
  while tree and (tree:lang() == "markdown_inline" or not ts.query.get(tree:lang(), "textobjects")) do
    tree = tree:parent()
  end
  return tree
end

--- Whether lhs runs the treesitter select or move in the current buffer and mode, rather than the key's own meaning
---@param lhs string
---@param mode string
function M.ours(lhs, mode)
  if mode ~= "n" and selects[lhs] then
    local tree = cursor_tree(vim.api.nvim_get_current_buf())
    return tree ~= nil and has(tree:lang(), selects[lhs].query)
  end
  local move = moves[lhs]
  if not move or (vim.wo.diff and (lhs == "]c" or lhs == "[c")) then
    return false
  end
  local parser = parser_of(vim.api.nvim_get_current_buf())
  return parser ~= nil and has(parser:lang(), move.query)
end

function M.run(lhs)
  if selects[lhs] then
    return require("nvim-treesitter-textobjects.select").select_textobject(selects[lhs].query, "textobjects")
  end
  require("nvim-treesitter-textobjects.move")[moves[lhs].fn](moves[lhs].query, "textobjects")
end

function M.shadowed(mode, lhs) shadowed[mode .. lhs].callback() end

---@param mode string
---@param lhs string
local function dispatch(mode, lhs)
  return function()
    if M.ours(lhs, mode) then
      return ("<Cmd>lua require('config.textobjects').run(%q)<CR>"):format(lhs)
    end
    local map = shadowed[mode .. lhs]
    if not map then
      return lhs
    end
    if map.callback then
      if map.expr == 1 then
        return map.callback()
      end
      return ("<Cmd>lua require('config.textobjects').shadowed(%q, %q)<CR>"):format(mode, lhs)
    end
    return map.expr == 1 and vim.api.nvim_eval(map.rhs) or map.rhs
  end
end

---@param modes string[]
---@param lhs string
---@param desc string
local function take(modes, lhs, desc)
  for _, mode in ipairs(modes) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      if map.lhs == lhs and not mine[map.callback] then
        shadowed[mode .. lhs] = map
      end
    end
    local fn = dispatch(mode, lhs)
    mine[fn] = true
    vim.keymap.set(mode, lhs, fn, { expr = true, desc = desc })
  end
end

---@param select_specs table<string, {query: string, desc: string}>
---@param move_specs table<string, table<string, {query: string, desc: string}>> move function -> lhs -> spec
function M.setup(select_specs, move_specs)
  for lhs, obj in pairs(select_specs) do
    selects[lhs] = obj
    take({ "x", "o" }, lhs, obj.desc)
  end
  for fn, maps in pairs(move_specs) do
    for lhs, obj in pairs(maps) do
      moves[lhs] = { fn = fn, query = obj.query, desc = obj.desc }
      take({ "n", "x", "o" }, lhs, obj.desc)
    end
  end
end

return M
