return {
  settings = {
    Lua = {
      format = {
        enable = True,
      },
      diagnostics = {
        globals = { "vim", "spec" },
      },
      runtime = {
        version = "LuaJIT",
        special = {
          spec = "require",
        },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          [vim.fn.stdpath "config" .. "/lua"] = true,
        },
      },
      hint = {
        enable = false,
        arrayIndex = "Disable", -- "Enable" | "Auto" | "Disable"
        await = true,
        paramName = "All", -- "All" | "Literal" | "Disable"
        paramType = true,
        semicolon = "All", -- "All" | "Sameline" | "Disable"
        setType = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
}

