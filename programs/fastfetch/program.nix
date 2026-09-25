{
  tier = "shell";
  install = {
    linux.nixpkgs = "fastfetch";
    darwin.nixpkgs = "fastfetch";
    wsl.nixpkgs = "fastfetch";
  };
}
