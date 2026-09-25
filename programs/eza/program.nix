{
  tier = "shell";
  install = {
    linux.nixpkgs = "eza";
    darwin.nixpkgs = "eza";
    wsl.nixpkgs = "eza";
  };
}
