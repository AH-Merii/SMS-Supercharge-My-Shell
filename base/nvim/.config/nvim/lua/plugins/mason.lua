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
}

-- Servers used when their binary is on PATH, installed outside Mason
local path_lsps = { "clangd", "gopls", "intelephense", "yamlls" }

-- conform formatters and nvim-lint linters whose Mason package has another name
local package_names = {
  ruff_fix = "ruff",
  ruff_format = "ruff",
  ruff_organize_imports = "ruff",
  golangcilint = "golangci-lint",
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

--- Installs the Mason packages a buffer's filetype needs and that are not installed yet.
---@param ev vim.api.keyset.create_autocmd.callback_args
local function install_tools(ev)
  local ft = ev.match
  if handled[ft] or vim.bo[ev.buf].buftype ~= "" or #vim.api.nvim_list_uis() == 0 then
    return
  end
  handled[ft] = true

  local registry = require("mason-registry")
  registry.refresh(vim.schedule_wrap(function()
    local available = registry.get_all_package_names()
    if #available == 0 then
      return vim.notify("No Mason registry, so nothing was installed for " .. ft, vim.log.levels.ERROR, { title = "Mason" })
    end

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
    if #missing == 0 then
      return
    end

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
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserMasonInstall", { clear = true }),
        callback = install_tools,
      })
      require("mason-lspconfig").setup(opts)
      for _, server in ipairs(path_lsps) do
        local cmd = vim.lsp.config[server] and vim.lsp.config[server].cmd
        if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
          vim.lsp.enable(server)
        end
      end
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
