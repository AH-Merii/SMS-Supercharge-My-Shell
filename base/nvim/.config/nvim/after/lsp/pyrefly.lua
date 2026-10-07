---@brief
---
--- https://pyrefly.org/
---
---`pyrefly`, a faster Python type checker written in Rust.
--
-- `pyrefly` is still in development, so please report any errors to
-- our issues page at https://github.com/facebook/pyrefly/issues.

---@type vim.lsp.Config
return {
  filetypes = { "python" },
  root_markers = {
    "pyrefly.toml",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
    "pixi.toml",
  },
  -- type errors on where the root has a pyproject.toml or pyrefly.toml; pyrefly's own default wants [tool.pyrefly]
  on_init = function(client)
    local root = client.root_dir
    local on = root ~= nil and vim.iter({ "pyproject.toml", "pyrefly.toml" }):any(function(f) return vim.uv.fs_stat(vim.fs.joinpath(root, f)) ~= nil end)
    require("config.utils").pyrefly_type_errors(client, on)
  end,
  on_exit = function(code, _, _) vim.notify("Closing Pyrefly LSP exited with code: " .. code, vim.log.levels.INFO) end,
}
