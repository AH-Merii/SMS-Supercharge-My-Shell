{
  tier = "shell";
  install = {
    linux.nixpkgs = "direnv";
    darwin.nixpkgs = "direnv";
    wsl.nixpkgs = "direnv";
  };
}
