# rustc and cargo rather than rustup, whose toolchain would sit outside the lock file.
# See docs/adr/0002-rust-from-the-lock-file.md.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "rustc";
    darwin.nixpkgs = "rustc";
    wsl.nixpkgs = "rustc";
  };
}
