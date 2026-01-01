 Overview

This is a personal Neovim configuration focused on LSP-driven development with lazy loading and modular architecture. The config supports Go, Rust, Python, Lua, TypeScript, PHP, C/C++, and more.

## Architecture

### Initialization Flow

The loading sequence is strictly ordered in `init.lua`:

1. `core.lsp` - Configure diagnostic appearance before any LSP loads
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
│   │   └── lsp.lua          # Diagnostic configuration
│   ├── config/              # Editor configuration
│   │   ├── options.lua      # Vim options
│   │   ├── keymaps.lua      # Global keymaps
│   │   ├── autocmds.lua     # Autocommands
│   │   ├── helpers.lua      # LSP debugging commands
│   │   └── utils.lua        # Custom utilities
│   └── plugins/             # Plugin specifications (~18 files)
├── after/
│   ├── ftplugin/            # Filetype-specific configs
│   └── lsp/                 # LSP server-specific configs
└── servers.lua              # List of LSP servers
```

### Module Dependencies

- `config.keymaps` depends on `config.options` (needs `mapleader`)
- `config.helpers` depends on LSP clients being loaded (deferred via `VeryLazy`)
- All LSP configs in `after/lsp/` depend on `blink.cmp` for completion capabilities
- Plugin files are independent but may integrate with each other

## LSP Configuration

### Two-Tier System

**Tier 1: Automatic Setup** (`lua/plugins/mason.lua`)
- Mason-LSPConfig handles installation and basic configuration
- Mason-Tool-Installer manages formatters, linters, and debuggers
- Servers auto-launch when filetypes are detected

**Tier 2: Custom Configuration** (`after/lsp/[server].lua`)
- Each LSP server can have a custom config file that returns server-specific options
- These files are late-loaded after Neovim understands filetypes
- Example servers with custom configs: `gopls.lua`, `rust-analyzer.lua`, `ts-ls.lua`, `pyrefly.lua`, `intelephense.lua`, `zls.lua`

### Adding a New LSP Server

1. Add server name to `ensure_installed` in `lua/plugins/mason.lua`
2. Optionally create `after/lsp/[server].lua` for custom settings
3. Add formatters to `lua/plugins/conform.lua` under `formatters_by_ft`
4. Add linters to `lua/plugins/nvim-lint.lua` under `linters_by_ft`

### LSP Server Config Pattern

All custom LSP configs in `after/lsp/` must follow this structure:

```lua
local blink = require("blink.cmp")

return {
    cmd = { "server-name" },
    filetypes = { "filetype1", "filetype2" },
    root_markers = { "go.mod", ".git" },
    settings = {
        -- Server-specific settings
    },
    capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        blink.get_lsp_capabilities(),  -- Critical for completion
        { -- Optional additional capabilities
            fileOperations = { didRename = true, willRename = true }
        }
    ),
}
```

**Critical**: Always merge `blink.get_lsp_capabilities()` to enable completion.

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

Every LSP server config must merge blink completion capabilities:

```lua
local blink = require("blink.cmp")
capabilities = vim.tbl_deep_extend("force", {},
    vim.lsp.protocol.make_client_capabilities(),
    blink.get_lsp_capabilities()  -- Required
)
```

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
**Format file**: Handled automatically on save via Conform
**Lint file**: Handled automatically on events via nvim-lint

## Notes

- The `servers.lua` file is a reference list of LSP servers, not actively used by the config
- The `nvim-notes.lua` file is a plugin spec for note-taking (vault at `~/notes`)
- Diagnostic signs use Nerd Font icons (requires font support)
- Leader key is set in `lua/config/options.lua` (typically `<space>`)
