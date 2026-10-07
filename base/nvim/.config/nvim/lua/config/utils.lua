local M = {}

M.toggle_go_test = function()
  -- Get the current buffer's file name
  local current_file = vim.fn.expand("%:p")
  if string.match(current_file, "_test.go$") then
    -- If the current file ends with '_test.go', try to find the corresponding non-test file
    local non_test_file = string.gsub(current_file, "_test.go$", ".go")
    if vim.fn.filereadable(non_test_file) == 1 then
      -- Open the corresponding non-test file if it exists
      vim.cmd.edit(non_test_file)
    else
      print("No corresponding non-test file found")
    end
  else
    -- If the current file is a non-test file, try to find the corresponding test file
    local test_file = string.gsub(current_file, ".go$", "_test.go")
    if vim.fn.filereadable(test_file) == 1 then
      -- Open the corresponding test file if it exists
      vim.cmd.edit(test_file)
    else
      print("No corresponding test file found")
    end
  end
end

-- Copy the current file path and line number to the clipboard, use GitHub URL if in a Git repository
M.copyFilePathAndLineNumber = function()
  local current_file = vim.fn.expand("%:p")
  local current_line = vim.fn.line(".")
  local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree"):match("true")

  if is_git_repo then
    local current_repo = vim.fn.systemlist("git remote get-url origin")[1]
    local current_branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]

    -- Convert Git URL to GitHub web URL format
    current_repo = current_repo:gsub("git@github.com:", "https://github.com/")
    current_repo = current_repo:gsub("%.git$", "")

    -- Remove leading system path to repository root
    local repo_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if repo_root then
      current_file = current_file:sub(#repo_root + 2)
    end

    local url = string.format("%s/blob/%s/%s#L%s", current_repo, current_branch, current_file, current_line)
    vim.fn.setreg("+", url)
    print("Copied to clipboard: " .. url)
  else
    -- If not in a Git directory, copy the full file path
    vim.fn.setreg("+", current_file .. "#L" .. current_line)
    print("Copied full path to clipboard: " .. current_file .. "#L" .. current_line)
  end
end

--- Labels the buffer maps a runtime ftplugin set without a desc, so which-key shows the label, not the rhs.
---@param script string the ftplugin's file name, e.g. "python.vim"
---@param labels table<string, string> lhs to desc
M.label_ftplugin_maps = function(script, labels)
  for lhs, desc in pairs(labels) do
    for _, mode in ipairs({ "n", "x", "o" }) do
      local map = vim.fn.maparg(lhs, mode, false, true)
      local from = map.buffer == 1 and not map.desc and map.sid > 0 and vim.fn.getscriptinfo({ sid = map.sid })[1].name
      if from and vim.endswith(from, "/ftplugin/" .. script) then
        map.desc = desc
        vim.fn.mapset(map)
      end
    end
  end
end

-- A pyrefly.toml or [tool.pyrefly] governs the files under it, where typeCheckingMode does nothing
---@param dir? string
local function pyrefly_configured(dir)
  while dir do
    if vim.uv.fs_stat(vim.fs.joinpath(dir, "pyrefly.toml")) then
      return true
    end
    local pyproject = vim.fs.joinpath(dir, "pyproject.toml")
    if vim.uv.fs_stat(pyproject) then
      return vim.iter(io.lines(pyproject)):any(function(line) return line:match("^%s*%[tool%.pyrefly[%].]") ~= nil end)
    end
    local parent = vim.fs.dirname(dir)
    dir = parent ~= dir and parent or nil
  end
  return false
end

--- Whether pyrefly type-checks this client's files; with `on`, turns checking on or off first.
---@param client vim.lsp.Client
---@param on? boolean
---@return boolean
M.pyrefly_type_errors = function(client, on)
  if on ~= nil then
    local pyrefly = { typeCheckingMode = on and "default" or "basic", disableTypeErrors = not on and pyrefly_configured(client.root_dir) }
    client.settings = vim.tbl_deep_extend("force", client.settings, { python = { pyrefly = pyrefly } })
    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
  end
  return vim.tbl_get(client.settings, "python", "pyrefly", "typeCheckingMode") == "default"
end

return M
