return {
  settings = {
    Lua = {
      diagnostics = {
        -- This is already covered by the luacheck linter
        disable = {
          "unused-local",
          "unused-function",
          "unused-vararg",
          "unused-label",
        },
      },
    },
  },
}
