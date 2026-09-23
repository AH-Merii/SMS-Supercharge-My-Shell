{
  tier = "shell";
  install = {
    linux.nixpkgs = "sesh";
    darwin.nixpkgs = "sesh";
    wsl.nixpkgs = "sesh";
  };
}
