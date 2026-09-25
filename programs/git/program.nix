{
  tier = "shell";
  install = {
    linux.nixpkgs = "git";
    darwin.nixpkgs = "git";
    wsl.nixpkgs = "git";
  };
}
