 Overview

This is a personal Neovim configuration focused on LSP-driven development with lazy loading and modular architecture. The config supports Go, Rust, Python, Lua, TypeScript, PHP, Zig, Typst, and more.

## Architecture

### Initialization Flow

The loading sequence is strictly ordered in `init.lua`:

1. `core.lsp` - Configure diagnostic appearance and enable non-Mason LSP servers
2. `config.options` - Set Vim options & define `mapleader`
3. `config.keymaps` - Register global keymaps
4. `config.autocmds` - Setup autocommands and event hooks
5. `core.lazy` - Bootstrap Lazy.nvim and load all plugins
6. `config.helpers` - Loaded on `VeryLazy` event after plugins ready

**Critical**: This order ensures dependencies are met (e.g., `mapleader` defined before keymaps).

### Directory Structure

```
nvim/
├── init.lua                  # Entry point (loads modules in order)
├── lua/
│   ├── core/                 # Core framework initialization
│   │   ├── lazy.lua         # Plugin manager bootstrap
│   │   └── lsp.lua          # Diagnostics + vim.lsp.enable for non-Mason servers
│   ├── config/              # Editor configuration
│   │   ├── options.lua      # Vim options
│   │   ├── keymaps.lua      # Global keymaps
│   │   ├── autocmds.lua     # Autocommands
│   │   ├── helpers.lua      # LSP debugging commands
│   │   └── utils.lua        # Custom utilities
│   └── plugins/             # Plugin specifications (~18 files)
└── after/
    ├── ftplugin/            # Filetype-specific configs
    └── lsp/                 # LSP server-specific configs (after/lsp/<name>.lua)
```

### Module Dependencies

- `config.keymaps` depends on `config.options` (needs `mapleader`)
- `config.helpers` depends on LSP clients being loaded (deferred via `VeryLazy`)
- `blink.cmp` merges its completion capabilities into `vim.lsp.config("*")` on load, so every server gets them without per-server code
- Plugin files are independent but may integrate with each other

## LSP Configuration

### How Servers Are Enabled

Servers only start if something calls `vim.lsp.enable()` (see `:h lsp-config`). Two places do:

**Mason-installed servers** (`lua/plugins/mason.lua`)
- Mason-LSPConfig installs `ensure_installed` servers and auto-enables every installed Mason package that has an LSP config (including tools installed as linters/formatters, e.g. `ruff`, `biome`, `tflint`, `taplo`)
- Mason-Tool-Installer manages formatters, linters, and debuggers

**Toolchain-installed servers** (`lua/core/lsp.lua`)
- `gopls`, `rust_analyzer`, `zls`, `intelephense`, `yamlls` are expected on `$PATH` (installed by the Go/Rust/Zig toolchains, npm, composer) and enabled explicitly on `User LazyDone`, once nvim-lspconfig's defaults are on the runtimepath
- If the binary is missing the server silently does not start (the LSP log records it; `:LspInfo` prints the log path)

**Per-server overrides** (`after/lsp/<name>.lua`)
- Merged over nvim-lspconfig's `lsp/<name>.lua` defaults and `vim.lsp.config("*")`
- The file name must be the LSP config name, e.g. `rust_analyzer.lua`, `ts_ls.lua` (not the binary name)
- Current overrides: `gopls`, `rust_analyzer`, `ts_ls`, `pyrefly`, `lua_ls`, `intelephense`, `zls`, `yamlls`, `tinymist`

### Adding a New LSP Server

1. Mason-installed: add the server name to `ensure_installed_lsps` in `lua/plugins/mason.lua`. Toolchain-installed: add it to the `vim.lsp.enable` list in `lua/core/lsp.lua`
2. Optionally create `after/lsp/<name>.lua` for custom settings
3. Add formatters to `lua/plugins/conform.lua` under `formatters_by_ft`
4. Add linters to `lua/plugins/nvim-lint.lua` under `linters_by_ft` (skip tools that already run as an LSP server, or diagnostics show up twice)

### LSP Server Config Pattern

`after/lsp/<name>.lua` returns a `vim.lsp.Config` table; only the keys that differ from nvim-lspconfig's defaults are needed:

```lua
return {
    cmd = { "server-name" },
    filetypes = { "filetype1", "filetype2" },
    root_markers = { "go.mod", ".git" },
    settings = {
        -- Server-specific settings
    },
    -- Optional; deep-merged over Neovim's default client capabilities and blink.cmp's
    capabilities = {
        workspace = {
            fileOperations = { didRename = true, willRename = true },
        },
    },
}
```

Do not `require("blink.cmp")` here: `blink.cmp` already registers its capabilities for all servers via `vim.lsp.config("*")`.

## Plugin Management

### Lazy.nvim Loading Strategies

**Event-based** (load on buffer events):
```lua
{ "plugin/name", event = { "BufReadPost", "BufNewFile" } }
```

**Command-based** (load when command invoked):
```lua
{ "plugin/name", cmd = "CommandName" }
```

**Key-based** (load when keymap triggered):
```lua
{ "plugin/name", keys = { { "<leader>x", ":Command<CR>" } } }
```

**Filetype-based** (load for specific filetypes):
```lua
{ "plugin/name", ft = "lua" }
```

**Priority loading** (load immediately):
```lua
{ "plugin/name", priority = 1000, lazy = false }
```

### Adding a New Plugin

1. Create `lua/plugins/[name].lua`
2. Return Lazy plugin spec with appropriate loading strategy
3. Include keymaps in the `keys` table for lazy loading
4. Add `config` function for setup
5. Use `dependencies` table for plugin dependencies

## Custom Commands

The `lua/config/helpers.lua` file provides LSP debugging commands:

- `:LspStatus` - Quick client status
- `:LspInfo` - Comprehensive LSP information
- `:LspCapabilities` - Detailed capability list
- `:LspDiagnostics` - Diagnostic summary
- `:Status` - Full tooling status (LSP, formatters, linters, treesitter)

Neovim 0.12 provides `:lsp enable|disable|restart|stop` and `:checkhealth vim.lsp` natively (nvim-lspconfig skips its `:Lsp*` commands when `:lsp` exists).

The `lua/config/utils.lua` file provides utilities:

- `toggle_go_test()` - Toggle between Go test/implementation files
- `copyFilePathAndLineNumber()` - Copy GitHub URL with line number (in git repos) or absolute path

## Filetype-Specific Configuration

### Adding Filetype Behavior

**Option 1**: Create `after/ftplugin/[filetype].lua` for buffer-local settings and keymaps

Example structure:
```lua
local opts = { noremap = true, silent = false, buffer = true }
vim.keymap.set("n", "<space>x", ":.lua<CR>", opts)

vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 2
```

**Option 2**: Add filetype autocommand in `lua/config/autocmds.lua`

```lua
autocmd("FileType", {
    pattern = { "markdown", "text" },
    callback = function()
        vim.opt_local.spell = true
        vim.opt_local.wrap = true
    end,
})
```

## Important Patterns

### Blink + LSP Integration

`blink.cmp`'s `plugin/blink-cmp.lua` runs on load and merges `get_lsp_capabilities()` into `vim.lsp.config("*")`, which every server config inherits (`:h lsp-config-merge`). Server files should not merge capabilities themselves; only add extra capabilities (e.g. `workspace.fileOperations`) when a server needs them.

### Conditional Plugin Setup

Gracefully handle missing dependencies:

```lua
config = function(_, opts)
    require("plugin").setup(opts)

    local ok, dep = pcall(require, "dependency")
    if ok then
        dep.setup()
    else
        vim.notify("dependency not found", vim.log.levels.WARN)
    end
end
```

### VeryLazy Deferred Loading

For heavy utilities that depend on plugins being loaded:

```lua
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
        require("heavy.module")
    end,
})
```

### Autocommand Groups

Always use groups for organization and reloading:

```lua
local group = vim.api.nvim_create_augroup("MyGroup", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function() ... end,
})
```

## Key Integrations

### Formatting & Linting Chain

For each language, the tooling chain is:
1. **Conform.nvim** (primary formatter)
2. **nvim-lint** (linter)
3. **LSP** (fallback formatter if no conform formatter)

Configure in:
- `lua/plugins/conform.lua` - Add to `formatters_by_ft`
- `lua/plugins/nvim-lint.lua` - Add to `linters_by_ft`
- `lua/plugins/mason.lua` - Add tools to `ensure_installed`

### Mason Tool Paths

Mason tools install to `~/.local/share/nvim/mason/bin/`. When configuring tools (e.g., DAP), check Mason paths first:

```lua
local mason_tool = vim.fn.stdpath("data") .. "/mason/bin/tool"
if vim.fn.executable(mason_tool) == 1 then
    return mason_tool
end
return vim.fn.exepath("tool") or "tool"  -- Fallback to system
```

## Testing Changes

After modifying configuration:

1. Source the file: `<space>%` or `:source %`
2. Restart Neovim to test full initialization flow
3. Check plugin status: `:Lazy` (press `U` to update, `X` to clean)
4. Check LSP status: `:LspStatus` or `:Status`
5. Check for errors: `:messages`

## Common Tasks

**Update plugins**: `:Lazy update`
**Install missing tools**: `:Mason` (press `U` to update all)
**Check LSP logs**: `:LspInfo` shows log path
**Reload config**: Restart Neovim (changes to `init.lua` and core modules require restart)
**Format file**: The `BufWritePre` autocmd in `lua/plugins/snacks.lua` calls Conform's `format_buffer()`; toggle with `<leader>Tf`
**Lint file**: Handled automatically on open/save/InsertLeave via nvim-lint

## Notes

- Diagnostic signs use Nerd Font icons (requires font support)
- Leader key is set in `lua/config/options.lua` (typically `<space>`)
