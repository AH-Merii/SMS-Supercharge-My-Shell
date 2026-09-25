{
  tier = "shell";
  install = {
    linux.nixpkgs = "starship";
    darwin.nixpkgs = "starship";
    wsl.nixpkgs = "starship";
  };
}
