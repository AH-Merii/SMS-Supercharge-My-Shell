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

local at_cursor = {} ---@type {key: string?, parser: vim.treesitter.LanguageTree?, tree: vim.treesitter.LanguageTree?}

--- tree_at the cursor, once per change and cursor position: which-key asks it for every select key on each popup
---@param buf integer
local function cursor_tree(buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local key = table.concat({ buf, vim.api.nvim_buf_get_changedtick(buf), row, col }, ":")
  local parser = parser_of(buf)
  if at_cursor.key ~= key or at_cursor.parser ~= parser then
    at_cursor = { key = key, parser = parser, tree = tree_at(buf, row - 1, col) }
  end
  return at_cursor.tree
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
---@param quick? boolean keep the state of an earlier change: only its languages are of use then
local function buffer_state(buf, quick)
  local parser = parser_of(buf)
  if not parser then
    return
  end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local state = states[parser]
  if not state or (state.tick ~= tick and not quick) then
    pcall(parser.parse, parser, true)
    state = { tick = tick, langs = {}, trees = {}, captures = {} }
    parser:for_each_tree(function(_, tree) state.langs[tree:lang()] = true end)
    states[parser] = state
  end
  return state, parser
end

--- Every capture of one tree, as upstream reads them: Range6 lists by capture name. Each range also carries its
--- language and the node type of the thing it belongs to: the match's outer node for an inner capture, else its own
---@param first? integer only matches that reach rows first to last
---@param last? integer
local function tree_captures(buf, tree, lang, first, last)
  local query = assert(ts.query.get(lang, "textobjects"))
  local out = {}
  local function add(name, range, kind)
    range.lang, range.kind = lang, kind
    out[name] = out[name] or {}
    table.insert(out[name], range)
  end
  local root = tree:root()
  local start_row, _, end_row = root:range()
  for _, match, metadata in query:iter_matches(root, buf, math.max(start_row, first or 0), math.min(end_row, last or end_row) + 1) do
    local single = {} ---@type table<string, TSNode>
    for id, nodes in pairs(match) do
      if #nodes == 1 and not (metadata[id] and metadata[id].range) then
        single[query.captures[id]] = nodes[1]
      end
    end
    for id, nodes in pairs(match) do
      local name = query.captures[id]
      local range = ts.get_range(nodes[1], buf, metadata[id])
      if #nodes > 1 then
        local _, _, _, end_row_, end_col, end_byte = nodes[#nodes]:range(true)
        range[4], range[5], range[6] = end_row_, end_col, end_byte
      end
      local kind = single[name:gsub("%.inner$", ".outer")] or single[name]
      add(name, range, kind and kind:type())
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

--- The buffer's languages as of its last full parse, plus those parsed since: no parse of every injection after a change
---@param buf integer
local function known_langs(buf)
  local state, parser = buffer_state(buf, true)
  if not state then
    return {}
  end
  local langs = vim.tbl_extend("force", {}, state.langs)
  parser:for_each_tree(function(_, tree) langs[tree:lang()] = true end)
  return langs
end

--- Whether lhs runs the treesitter select or move in the current buffer and mode, rather than the key's own meaning
---@param lhs string
---@param mode string
---@param quick? boolean for a label or icon: a move takes the languages known so far, see known_langs
function M.ours(lhs, mode, quick)
  if mode ~= "n" and selects[lhs] then
    local tree = cursor_tree(vim.api.nvim_get_current_buf())
    return tree ~= nil and has(tree:lang(), selects[lhs].query)
  end
  local move = moves[lhs]
  if not move or (vim.wo.diff and (lhs == "]c" or lhs == "[c")) then
    return false
  end
  local buf = vim.api.nvim_get_current_buf()
  local state, parser = buffer_state(buf, quick)
  if not state then
    return false
  end
  if not searches_all then
    return has(parser:lang(), move.query)
  end
  for lang in pairs(quick and known_langs(buf) or state.langs) do
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

-- labels ---------------------------------------------------------------------------------------------------------

-- node types that name the object itself, beyond the object's own name
local same_kind = {
  ["function"] = { "method", "func", "lambda", "arrow", "closure" },
  loop = { "for", "while", "repeat", "do" },
  conditional = { "if", "switch", "case", "match", "ternary", "elif", "else" },
}
-- objects whose node type says nothing: an argument is an identifier or an expression
local name_only = { parameter = true, call = true }

--- desc and the language, with the object named by its node type where that is a different kind of thing
---@param desc string "Around function", "Next function end"
---@param query string
---@param range? table a capture range from tree_captures
---@param langs string
local function describe(desc, query, range, langs)
  local object = query:match("^@(%w+)")
  local kind = range and range.kind
  if kind and not name_only[object] then
    local words = vim.split(kind, "_", { trimempty = true })
    if not vim.list_contains(words, object) and not vim.iter(same_kind[object] or {}):any(function(w) return vim.list_contains(words, w) end) then
      desc = desc:match("^%S+") .. " " .. table.concat(words, " ") .. (desc:match(" end$") or "")
    end
  end
  return ("%s (%s)"):format(desc, langs)
end

local presets ---@type table<string, string>?
local native_labels = {} ---@type table<string, string|false>
local help ---@type table<string, table<string, {note: string, desc: string}>>? section tag -> keys -> entry

--- Neovim's index of commands, $VIMRUNTIME/doc/index.txt, by section and keys: "]p" in "[" is note 2, `like "p", ...`
local function help_index()
  if help then
    return help
  end
  help = {}
  local ok, lines = pcall(vim.fn.readfile, vim.fs.joinpath(vim.env.VIMRUNTIME, "doc", "index.txt"))
  local section, entry, header = nil, nil, false
  for _, line in ipairs(ok and lines or {}) do
    local keys, rest = line:match("^|[^|]+|%s+(.-)\t+(.*)$")
    local more = line:match("^%s+(%S[^\t]*)$")
    if header then
      local tag = line:match("%*([^*]+)%*")
      help[tag or ""] = help[tag or ""] or {}
      section, header = help[tag or ""], false
    elseif line:match("^====") then
      header, entry = true, nil
    elseif keys and section then
      local note, desc = rest:match("^(%d?)%s*(.-)%s*$")
      entry = { note = note, desc = desc }
      section[keys] = section[keys] or entry
    elseif more and entry then
      entry.desc = entry.desc .. " " .. more
    else
      entry = nil
    end
  end
  return help
end

local NORMAL = { "normal-index", "CTRL-W", "[", "g", "z" }

--- What Neovim's index says lhs does in mode: a text object, a command of that mode, or a Normal mode command, which
--- also works in Visual mode and after an operator if it moves the cursor
local function help_desc(lhs, mode)
  local index = help_index()
  local function find(sections, motion)
    for _, tag in ipairs(sections) do
      local entry = index[tag] and index[tag][lhs]
      if entry and (not motion or entry.note == "1") then
        return entry.desc:sub(1, 1):upper() .. entry.desc:sub(2)
      end
    end
  end
  if mode == "n" then
    return find(NORMAL)
  end
  return find({ "objects", mode == "x" and "visual-index" or "operator-pending-index" }) or find(NORMAL, mode == "o")
end

--- What the key's own meaning is called: the shadowed map's desc, else which-key's preset label, else Neovim's index;
--- nil where the key has no meaning of its own in mode
local function native_label(lhs, mode)
  local key = mode .. lhs
  if native_labels[key] == nil then
    if not presets then
      presets = {}
      local function scan(t)
        if type(t) ~= "table" then
          return
        end
        if type(t[1]) == "string" and type(t.desc) == "string" then
          presets[t[1]] = presets[t[1]] or t.desc
        end
        for _, v in pairs(t) do
          scan(v)
        end
      end
      local ok, mod = pcall(require, "which-key.plugins.presets")
      scan(ok and mod or nil)
    end
    local map, preset = shadowed[key], presets[lhs]
    if map and map.desc then
      native_labels[key] = map.desc
    elseif preset and lhs:match("^[ai].$") then
      -- "inner paragraph" and "paragraph" read like ours: "Inside paragraph", "Around paragraph"
      native_labels[key] = lhs:sub(1, 1) == "i" and ("Inside " .. preset:gsub("^inner ", "")) or ("Around " .. preset)
    elseif preset then
      native_labels[key] = preset:sub(1, 1):upper() .. preset:sub(2)
    else
      native_labels[key] = help_desc(lhs, mode) or (map and (map.rhs or lhs)) or false
    end
  end
  return native_labels[key] or nil
end

--- Whether which-key lists lhs in mode: where it runs the treesitter key, or where the key has a meaning of its own
---@param lhs string
---@param mode string
function M.shown(lhs, mode)
  if not selects[lhs] and not moves[lhs] then
    return true
  end
  local ok, shown = pcall(function() return native_label(lhs, mode) ~= nil or M.ours(lhs, mode, true) end)
  return not ok or shown
end

--- Upstream's best_range_at_point: the smallest range around the point, else the first ahead, else the last behind
local function best_at(ranges, row, col, opts)
  local around, ahead, behind
  local function len(r) return r[6] - r[3] end
  for _, r in ipairs(ranges) do
    if contains(r, row, col) then
      if not around or len(r) < len(around) or (len(r) == len(around) and r[3] < around[3]) then
        around = r
      end
    elseif opts.lookahead then
      if (r[1] > row or (r[1] == row and r[2] > col)) and (not ahead or r[3] < ahead[3] or (r[3] == ahead[3] and len(r) > len(ahead))) then
        ahead = r
      end
    elseif opts.lookbehind then
      if (r[1] < row or (r[1] == row and r[2] < col)) and (not behind or r[3] > behind[3] or (r[3] == behind[3] and len(r) < len(behind))) then
        behind = r
      end
    end
  end
  return around or ahead or behind
end

--- Upstream's textobject_at_point over given captures: an inner object is looked for inside the outer one at the point
local function at_point(caps, name, row, col, opts)
  local ranges = caps[name] or {}
  if vim.endswith(name, "outer") then
    return best_at(ranges, row, col, opts)
  end
  local outer = name:gsub("%..*", ".outer")
  outer = outer == name and name .. ".outer" or outer
  local around = best_at(caps[outer] or {}, row, col, {})
  local within = around
      and vim.tbl_filter(function(r) return contains(around, r[1], r[2]) and (r[4] < around[4] or (r[4] == around[4] and r[5] <= around[5])) end, ranges)
    or {}
  if #within == 0 then
    return best_at(ranges, row, col, opts)
  end
  return best_at(within, row, col, opts) or best_at(within, around[1], around[2], { lookahead = true })
end

local NEAR = 100 -- rows on each side of the cursor a select label searches
local near = {} ---@type {key: string?, caps: table?}

local function select_label(lhs)
  local obj, buf = selects[lhs], vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local tree = assert(cursor_tree(buf))
  local root = tree:tree_for_range({ row, col, row, col }, { ignore_injections = true })
  local range
  if root then
    local key = table.concat({ buf, vim.api.nvim_buf_get_changedtick(buf), root:root():id(), row }, ":")
    if near.key ~= key then
      near = { key = key, caps = tree_captures(buf, root, tree:lang(), row - NEAR, row + NEAR) }
    end
    local name, config = obj.query:sub(2), require("nvim-treesitter-textobjects.config").select
    range = at_point(near.caps, name, row, col, { lookahead = config.lookahead, lookbehind = config.lookbehind })
    -- the limit the select applies
    if range and range[1] ~= row and not contains(range, row, col) then
      local outer = name:gsub("%.inner$", ".outer")
      local around = outer ~= name and best_at(near.caps[outer] or {}, row, col, {})
      if not (around and contains(around, range[1], range[2])) then
        range = nil
      end
    end
  end
  return describe(obj.desc, obj.query, range, tree:lang())
end

local seen = {} ---@type {key: string?, caps: table?}

--- Every capture that reaches the visible part of the window, in every language
local function visible_captures(buf)
  local parser = parser_of(buf)
  local first, last = vim.fn.line("w0") - 1, vim.fn.line("w$") - 1
  local key = table.concat({ buf, vim.api.nvim_buf_get_changedtick(buf), first, last }, ":")
  if parser and seen.key ~= key then
    pcall(parser.parse, parser, { first, last + 1 })
    local caps = {}
    parser:for_each_tree(function(tree, ltree)
      local s, _, e = tree:root():range()
      if s <= last and e >= first and ts.query.get(ltree:lang(), "textobjects") then
        for name, ranges in pairs(tree_captures(buf, tree, ltree:lang(), first, last)) do
          caps[name] = vim.list_extend(caps[name] or {}, ranges)
        end
      end
    end)
    seen = { key = key, caps = caps }
  end
  return parser and seen.caps or {}
end

local FULL = 500 -- lines up to which a move label searches the whole buffer, as the move does

--- The range a move would go to with no count, by upstream's rules for starts and ends; past FULL lines, if it is on screen
local function move_target(move, buf)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local forward, start = move.fn:find("next") ~= nil, move.fn:find("start") ~= nil
  local name, best = move.query:sub(2), nil
  local full = vim.api.nvim_buf_line_count(buf) <= FULL
  for _, r in ipairs(full and capture_ranges(buf, name) or visible_captures(buf)[name] or {}) do
    local r_row, r_col = r[1], r[2]
    if not start then
      r_row, r_col = r[5] == 0 and r[4] - 1 or r[4], r[5] == 0 and 0 or r[5] - 1
    end
    local byte = start and r[3] or r[6]
    if forward and (r_row > row or (r_row == row and r_col > col)) and (not best or byte < best[1]) then
      best = { byte, r }
    elseif not forward and (r_row < row or (r_row == row and r_col < col)) and (not best or byte > best[1]) then
      best = { byte, r }
    end
  end
  return best and best[2]
end

local function move_label(lhs)
  local move, buf = moves[lhs], vim.api.nvim_get_current_buf()
  local range = move_target(move, buf)
  local langs = range and range.lang
  if not langs then
    local all = vim.tbl_keys(known_langs(buf))
    table.sort(all)
    langs = table.concat(vim.tbl_filter(function(lang) return has(lang, move.query) end, all), ", ")
  end
  return describe(move.desc, move.query, range, langs)
end

local cache = { at = nil, labels = {} }

--- The label for lhs in the current buffer and mode: what the key does there
---@param lhs string
---@param mode string
function M.label(lhs, mode)
  if not selects[lhs] and not moves[lhs] then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  local at = table.concat({ buf, vim.api.nvim_buf_get_changedtick(buf), unpack(vim.api.nvim_win_get_cursor(0)) }, ":")
  if cache.at ~= at then
    cache = { at = at, labels = {} }
  end
  local key = mode .. lhs
  if not cache.labels[key] then
    local ok, label = pcall(function()
      if not M.ours(lhs, mode, true) then
        return native_label(lhs, mode)
      end
      return selects[lhs] and mode ~= "n" and select_label(lhs) or move_label(lhs)
    end)
    cache.labels[key] = ok and label or (selects[lhs] or moves[lhs]).desc
  end
  return cache.labels[key]
end

return M
