-- vim.g.install_tools: "ask" (default) before installing what a filetype lacks, "auto" to install without asking, "off"

-- LSP *server* names (not Mason package names), installed when a file of one of their filetypes opens
local servers = {
  "pyrefly",
  "lua_ls",
  "fish_lsp",
  "marksman",
  "ts_ls",
  "tinymist", -- Typst
  "rust_analyzer",
  "terraformls",
  "gopls",
  "intelephense",
  "yamlls",
  "clangd",
}

-- conform formatters and nvim-lint linters whose Mason package has another name
local package_names = {
  ruff_fix = "ruff",
  ruff_format = "ruff",
  ruff_organize_imports = "ruff",
  golangcilint = "golangci-lint",
  clang_format = "clang-format",
  terraform_fmt = "terraform",
}

-- Mason packages a filetype needs that no formatter, linter or server above names
local extra_packages = {
  toml = { "taplo", "pyproject-fmt" }, -- conform's toml function picks one by availability
  yaml = { "actionlint" }, -- GitHub workflows, see nvim-lint.lua
}

local server_filetypes -- server name -> filetypes, resolved once

--- Formatter, linter, server and extra package names for a filetype; not all are Mason packages.
---@param filetype string
---@return string[]
local function tool_names(filetype)
  local formatters_by_ft = require("plugins.conform").opts.formatters_by_ft
  local linters_by_ft = require("lint").linters_by_ft
  local server_packages = require("mason-lspconfig").get_mappings().lspconfig_to_package
  if not server_filetypes then
    server_filetypes = {}
    for _, server in ipairs(servers) do
      server_filetypes[server] = (vim.lsp.config[server] or {}).filetypes or {}
    end
  end

  local names = {}
  -- "yaml.docker-compose" also gets yaml's tools
  for _, ft in ipairs({ filetype, unpack(vim.split(filetype, ".", { plain = true })) }) do
    local formatters = formatters_by_ft[ft]
    vim.list_extend(names, type(formatters) == "table" and formatters or {})
    vim.list_extend(names, linters_by_ft[ft] or {})
    vim.list_extend(names, extra_packages[ft] or {})
    for server, fts in pairs(server_filetypes) do
      if vim.list_contains(fts, ft) then
        table.insert(names, server_packages[server])
      end
    end
  end
  return names
end

local handled = {} -- filetypes whose tools were looked at this session
local queue = {} -- filetypes waiting for their prompt; one prompt at a time
local asking = false
local never_file = vim.fs.joinpath(vim.fn.stdpath("state"), "install_tools_never.json")
local never -- filetypes answered "Never", read from never_file once

---@return string[]
local function never_list()
  if not never then
    local ok, list = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(never_file), "\n")) end)
    never = ok and list or {}
  end
  return never
end

--- Mason packages the filetype needs that are neither installed nor installing.
---@param ft string
---@return string[]
local function missing_packages(ft)
  local registry = require("mason-registry")
  local available = registry.get_all_package_names()
  local missing = {}
  for _, name in ipairs(tool_names(ft)) do
    name = package_names[name] or name
    if vim.list_contains(available, name) and not vim.list_contains(missing, name) then
      local pkg = registry.get_package(name)
      if not pkg:is_installed() and not pkg:is_installing() then
        table.insert(missing, name)
      end
    end
  end
  return missing
end

---@param ft string
local function install(ft)
  local missing = missing_packages(ft)
  if #missing == 0 then
    return
  end
  local registry = require("mason-registry")
  vim.notify(("Installing %s for %s"):format(table.concat(missing, ", "), ft), vim.log.levels.INFO, { title = "Mason" })
  for _, name in ipairs(missing) do
    registry.get_package(name):install(
      {},
      vim.schedule_wrap(function(success)
        if success then
          vim.notify("Installed " .. name, vim.log.levels.INFO, { title = "Mason" })
        else
          vim.notify(("Could not install %s, see :MasonLog"):format(name), vim.log.levels.ERROR, { title = "Mason" })
        end
      end)
    )
  end
end

--- Asks about the next queued filetype, once startup is done and no other prompt is open.
local function ask_next()
  if asking or vim.v.vim_did_enter == 0 or #queue == 0 then
    return
  end
  local ft = table.remove(queue, 1)
  local missing = missing_packages(ft)
  if #missing == 0 then
    return ask_next()
  end
  asking = true
  vim.ui.select({ "Yes", "Not now", "Never" }, { prompt = ("Install %s for %s?"):format(table.concat(missing, ", "), ft) }, function(choice)
    if choice == "Yes" then
      install(ft)
    elseif choice == "Never" then
      never = nil -- re-read, another session may have written since
      table.insert(never_list(), ft)
      vim.fn.mkdir(vim.fs.dirname(never_file), "p")
      vim.fn.writefile({ vim.json.encode(never_list()) }, never_file)
      vim.notify(("Not installing tools for %s; remove it from %s to be asked again"):format(ft, never_file), vim.log.levels.INFO, { title = "Mason" })
    end
    asking = false
    vim.schedule(ask_next)
  end)
end

--- Offers to install, or installs, the Mason packages a buffer's filetype needs and lacks.
---@param ev vim.api.keyset.create_autocmd.callback_args
local function install_tools(ev)
  local ft = ev.match
  local mode = vim.g.install_tools or "ask"
  if mode == "off" or handled[ft] or vim.bo[ev.buf].buftype ~= "" or #vim.api.nvim_list_uis() == 0 or vim.list_contains(never_list(), ft) then
    return
  end
  handled[ft] = true

  local registry = require("mason-registry")
  registry.refresh(vim.schedule_wrap(function()
    if #registry.get_all_package_names() == 0 then
      return vim.notify("No Mason registry, so nothing was installed for " .. ft, vim.log.levels.ERROR, { title = "Mason" })
    end
    if mode == "auto" then
      install(ft)
    elseif #missing_packages(ft) > 0 then
      table.insert(queue, ft)
      ask_next()
    end
  end))
end

return {
  ---------------------------------------------------------------------------
  -- Mason core
  ---------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
      },
    },
  },

  ---------------------------------------------------------------------------
  -- LSP bridge
  ---------------------------------------------------------------------------
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    keys = {
      {
        "<leader>lr",
        function() vim.lsp.buf.rename() end,
        mode = "n",
        desc = "LSP Rename",
      },
    },
    opts = {
      -- Automatically enable installed servers
      automatic_enable = true,
    },
    config = function(_, opts)
      local group = vim.api.nvim_create_augroup("UserMasonInstall", { clear = true })
      vim.api.nvim_create_autocmd("FileType", { group = group, callback = install_tools })
      vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = vim.schedule_wrap(ask_next) })
      require("mason-lspconfig").setup(opts)
    end,
  },

  ---------------------------------------------------------------------------
  -- DAP (Python)
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-dap",
    optional = true,
  },
}
