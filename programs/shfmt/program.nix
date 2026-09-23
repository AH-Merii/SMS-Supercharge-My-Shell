{
  tier = "shell";
  install = {
    linux.nixpkgs = "shfmt";
    darwin.nixpkgs = "shfmt";
    wsl.nixpkgs = "shfmt";
  };
}
