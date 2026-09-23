{
  tier = "shell";
  install = {
    linux.nixpkgs = "lazygit";
    darwin.nixpkgs = "lazygit";
    wsl.nixpkgs = "lazygit";
  };
}
