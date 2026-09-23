{
  tier = "shell";
  install = {
    linux.nixpkgs = "gh";
    darwin.nixpkgs = "gh";
    wsl.nixpkgs = "gh";
  };
}
