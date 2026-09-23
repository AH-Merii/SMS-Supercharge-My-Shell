{
  tier = "shell";
  install = {
    linux.nixpkgs = "ripgrep";
    darwin.nixpkgs = "ripgrep";
    wsl.nixpkgs = "ripgrep";
  };
}
