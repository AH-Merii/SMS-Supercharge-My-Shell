{
  tier = "shell";
  install = {
    linux.nixpkgs = "fd";
    darwin.nixpkgs = "fd";
    wsl.nixpkgs = "fd";
  };
}
