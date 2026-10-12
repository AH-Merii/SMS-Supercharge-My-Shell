-- vim.o.tabstop = 2

require("config.utils").label_ftplugin_maps("go.vim", {
  ["]]"] = "Next top-level func/type",
  ["[["] = "Previous top-level func/type",
  ["]["] = "Next top-level block end",
  ["[]"] = "Previous top-level block end",
})
