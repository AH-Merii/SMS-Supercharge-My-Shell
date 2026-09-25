# the directory is named for the program, the config tree for the binary
{
  tier = "shell";
  install = {
    linux.nixpkgs = "neovim";
    darwin.nixpkgs = "neovim";
    wsl.nixpkgs = "neovim";
  };
}
