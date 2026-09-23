# rustup rather than rustc and cargo separately: a toolchain manager is what Rust development
# expects -- components, targets and a per-project override all go through it -- and it is what
# mise's rust backend was already driving. The toolchain it fetches is therefore outside the
# lock file; the lock file pins the manager.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "rustup";
    darwin.nixpkgs = "rustup";
    wsl.nixpkgs = "rustup";
  };
}
