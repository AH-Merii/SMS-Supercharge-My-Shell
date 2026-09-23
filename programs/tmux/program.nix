{
  tier = "shell";
  install = {
    linux.nixpkgs = "tmux";
    darwin.nixpkgs = "tmux";
    wsl.nixpkgs = "tmux";
  };
}
