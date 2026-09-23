# The compiler itself from the lock file, rather than rustup. rustup would lock the manager and
# leave the toolchain it downloads outside the lock file, which is the one thing a single lock
# file exists to prevent. Nothing is lost by dropping it: a project pins its own toolchain
# through mise, which bootstraps a rustup of its own when none is there and whose default
# profile carries clippy and rustfmt, so this default only ever serves work outside a project.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "rustc";
    darwin.nixpkgs = "rustc";
    wsl.nixpkgs = "rustc";
  };
}
