{
  tier = "shell";
  install = {
    linux.nixpkgs = "bun";
    darwin.nixpkgs = "bun";
    wsl.nixpkgs = "bun";
  };
}
