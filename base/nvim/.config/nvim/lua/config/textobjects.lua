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

--- The innermost language at (row, col) that has text objects; markdown_inline is the prose of markdown
---@param buf integer
---@param row integer 0-based
---@param col integer
---@return vim.treesitter.LanguageTree?
local function tree_at(buf, row, col)
  local parser = parser_of(buf)
  if not parser then
    return
  end
  pcall(parser.parse, parser, { row, row + 1 })
  local tree = parser:language_for_range({ row, col, row, col })
  while tree and (tree:lang() == "markdown_inline" or not ts.query.get(tree:lang(), "textobjects")) do
    tree = tree:parent()
  end
  return tree
end

---@param buf integer
local function cursor_tree(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  return tree_at(buf, row - 1, col)
end

---@param range Range6
local function contains(range, row, col)
  return (range[1] < row or (range[1] == row and range[2] <= col)) and (range[4] > row or (range[4] == row and range[5] > col))
end

--- Upstream's textobject_at_point limited to the language tree at the point, with lookahead only on the point's
--- line or inside the enclosing outer object, so a select never edits another fence or a far line
local function limited(original, query, group, buf, pos, opts)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  pos = pos or vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local tree = tree_at(buf, row, col)
  if not tree or not has(tree:lang(), query) then
    return nil
  end
  local root = tree:tree_for_range({ row, col, row, col }, { ignore_injections = true })
  local parser = assert(parser_of(buf))
  local proxy = setmetatable({
    parse = function() end,
    for_each_tree = function(_, fn)
      if root then
        fn(root, tree)
      end
    end,
  }, {
    __index = function(_, key)
      local value = parser[key]
      return type(value) == "function" and function(_, ...) return value(parser, ...) end or value
    end,
  })
  local get_parser = ts.get_parser
  ts.get_parser = function(b, ...) return b == buf and proxy or get_parser(b, ...) end
  local ok, range = pcall(original, query, group, buf, pos, opts)
  if ok and range and range[1] ~= row and not contains(range, row, col) then
    local outer = query:gsub("%.inner$", ".outer")
    local fine, around = false, nil
    if outer ~= query and has(tree:lang(), outer) then
      fine, around = pcall(original, outer, group, buf, pos, {})
    end
    if not (fine and around and contains(around, range[1], range[2])) then
      range = nil
    end
  end
  ts.get_parser = get_parser
  assert(ok, range)
  return range
end

do
  local ok, shared = pcall(require, "nvim-treesitter-textobjects.shared")
  local original = ok and type(shared.textobject_at_point) == "function" and shared.textobject_at_point
  if original then
    shared.textobject_at_point = function(...)
      local fine, range = pcall(limited, original, ...)
      if fine then
        return range
      end
      return original(...) -- upstream changed under the wrapper: unlimited, as before
    end
  end
end

local states = setmetatable({}, { __mode = "k" }) ---@type table<vim.treesitter.LanguageTree, table>

--- The buffer's languages with every injection parsed, and the capture ranges found so far, until the next change
---@param buf integer
local function buffer_state(buf)
  local parser = parser_of(buf)
  if not parser then
    return
  end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local state = states[parser]
  if not state or state.tick ~= tick then
    pcall(parser.parse, parser, true)
    state = { tick = tick, langs = {}, trees = {}, captures = {} }
    parser:for_each_tree(function(_, tree) state.langs[tree:lang()] = true end)
    states[parser] = state
  end
  return state, parser
end

--- Every capture of one tree, as upstream reads them: Range6 lists by capture name
local function tree_captures(buf, tree, lang)
  local query = assert(ts.query.get(lang, "textobjects"))
  local out = {}
  local function add(name, range)
    out[name] = out[name] or {}
    table.insert(out[name], range)
  end
  local root = tree:root()
  local start_row, _, end_row = root:range()
  for _, match, metadata in query:iter_matches(root, buf, start_row, end_row + 1) do
    for id, nodes in pairs(match) do
      local range = ts.get_range(nodes[1], buf, metadata[id])
      if #nodes > 1 then
        local _, _, _, end_row_, end_col, end_byte = nodes[#nodes]:range(true)
        range[4], range[5], range[6] = end_row_, end_col, end_byte
      end
      add(query.captures[id], range)
    end
    if metadata.range and metadata.range[7] then
      add(metadata.range[7], { unpack(metadata.range, 1, 6) })
    end
  end
  return out
end

--- The ranges of a capture in every language tree of the buffer
---@param capture string "function.outer"
local function capture_ranges(buf, capture)
  local state, parser = buffer_state(buf)
  if not state then
    return {}
  end
  if not state.captures[capture] then
    local out = {}
    parser:for_each_tree(function(tree, ltree)
      if has(ltree:lang(), "@" .. capture) then
        state.trees[tree] = state.trees[tree] or tree_captures(buf, tree, ltree:lang())
        vim.list_extend(out, state.trees[tree][capture] or {})
      end
    end)
    state.captures[capture] = out
  end
  return state.captures[capture]
end

local across = false -- true while one of our moves runs, so a move searches every language tree
local searches_all = false
do
  local ok, shared = pcall(require, "nvim-treesitter-textobjects.shared")
  local original = ok and type(shared.find_best_range) == "function" and shared.find_best_range
  if original then
    searches_all = true
    shared.find_best_range = function(buf, capture, group, keep, score)
      if not across then
        return original(buf, capture, group, keep, score)
      end
      local fine, all = pcall(capture_ranges, buf, (capture:gsub("^@", "")))
      if not fine then
        return original(buf, capture, group, keep, score)
      end
      local best, best_score
      for _, range in ipairs(all) do
        if keep(range) then
          local s = score(range)
          if not best or s > best_score then
            best, best_score = range, s
          end
        end
      end
      return best
    end
  end
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
  local state, parser = buffer_state(vim.api.nvim_get_current_buf())
  if not state then
    return false
  end
  if not searches_all then
    return has(parser:lang(), move.query)
  end
  for lang in pairs(state.langs) do
    if has(lang, move.query) then
      return true
    end
  end
  return false
end

function M.run(lhs)
  if selects[lhs] then
    return require("nvim-treesitter-textobjects.select").select_textobject(selects[lhs].query, "textobjects")
  end
  across = true
  local ok, err = pcall(require("nvim-treesitter-textobjects.move")[moves[lhs].fn], moves[lhs].query, "textobjects")
  across = false
  assert(ok, err)
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
