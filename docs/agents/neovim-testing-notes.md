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
- **LSP servers can leak on exit.** The default `exit_timeout = false` closes a server's pipes
  without waiting.
  - A Go server that writes to stdout or stderr while shutting down then dies of SIGPIPE
    before its deferred cleanup. E.g. tflint's `--act-as-bundled-plugin` child is orphaned to
    `systemd --user`.
  - Fix: a per-server `exit_timeout` in `after/lsp/<server>.lua`.
  - Exit then waits for every client, so a server that ignores `exit` (terraform-ls) makes
    each quit cost the full timeout. Keep it small: 500 ms.
  - A typed `:qa` in the TUI hides the leak; headless `:qa`, closing the pane and SIGHUP show
    it.
- **GUI recipe:** on the leased `cachyos` VM, headless, never a window on the live desktop.
  - boot: `lease.sh acquire cachyos`, `lease.sh restore cachyos after-pr140`,
    `GL=headless test-ready.sh cachyos`, type the greeter password over QMP, then rsync the
    nvim builds, config and fixtures into the guest;
  - launch, in the guest: `niri msg action spawn -- ghostty --class=<unique>
    --gtk-single-instance=false -e <launcher> --listen <sock>`;
  - find the window with `niri msg -j windows` in the guest;
  - drive nvim over `<sock>` with `--remote-send` and `--remote-expr`;
  - capture from the host over VNC with `~/VMs/shot.sh cachyos <abs>`, after
    `niri msg action power-on-monitors` in the guest, because it blanks its monitor when idle.
