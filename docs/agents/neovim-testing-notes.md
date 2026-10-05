# Neovim testing notes

Neovim-specific facts from the 0.13 migration (2026-10-05). The general rules are in
[test-suites.md](test-suites.md) and [sandbox-isolation.md](sandbox-isolation.md).

- **Headless runs:**
  - lazy.nvim's VeryLazy must be fired by hand;
  - mason-lspconfig skips installs;
  - nightly `:checkhealth` is async;
  - which-key's config loads only after VimEnter.
- **Attach checks** must handle LSP servers whose `cmd` is a function (upstream `ts_ls`).
- **Mason wrapper scripts** hard-code their package path: lua-language-server, luacheck through
  `LUA_PATH`, yamllint, gersemi, pyproject-fmt.
- **tflint** run as a server leaves `tflint --act-as-bundled-plugin` children behind (under
  investigation).
- **GUI recipe:**
  - launch: `ghostty --class=<unique> --gtk-single-instance=false -e <launcher> --listen <sock>`;
  - find the window with `niri msg -j windows`;
  - capture with `niri msg action screenshot-window --id <id> --path <abs>`.
