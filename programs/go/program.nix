{
  tier = "shell";
  install = {
    linux.nixpkgs = "go";
    darwin.nixpkgs = "go";
    wsl.nixpkgs = "go";
  };
}
