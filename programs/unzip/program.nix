# Nothing in the repo calls unzip; neovim's Mason shells out to it to unpack language servers.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "unzip";
    darwin.nixpkgs = "unzip";
    wsl.nixpkgs = "unzip";
  };
}
