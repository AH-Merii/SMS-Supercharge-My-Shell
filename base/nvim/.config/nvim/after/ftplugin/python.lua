require("config.utils").label_ftplugin_maps("python.vim", {
  ["]]"] = "Next top-level def/class",
  ["[["] = "Previous top-level def/class",
  ["]["] = "Next top-level block end",
  ["[]"] = "Previous top-level block end",
  ["]m"] = "Next def/class line",
  ["[m"] = "Previous def/class line",
  ["]M"] = "Next def/class end",
  ["[M"] = "Previous def/class end",
})
