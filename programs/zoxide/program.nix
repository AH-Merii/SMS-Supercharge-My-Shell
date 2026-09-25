{
  tier = "shell";
  install = {
    linux.nixpkgs = "zoxide";
    darwin.nixpkgs = "zoxide";
    wsl.nixpkgs = "zoxide";
  };
}
