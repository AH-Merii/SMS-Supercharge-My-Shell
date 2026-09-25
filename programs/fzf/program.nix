{
  tier = "shell";
  install = {
    linux.nixpkgs = "fzf";
    darwin.nixpkgs = "fzf";
    wsl.nixpkgs = "fzf";
  };
}
