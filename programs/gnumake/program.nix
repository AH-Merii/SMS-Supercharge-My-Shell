# make but deliberately no compiler: a Nix cc-wrapper brings its own glibc and include paths
# and stops seeing system headers, where make only drives a build.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "gnumake";
    darwin.nixpkgs = "gnumake";
    wsl.nixpkgs = "gnumake";
  };
}
