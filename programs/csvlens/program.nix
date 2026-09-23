{
  tier = "shell";
  install = {
    linux.nixpkgs = "csvlens";
    darwin.nixpkgs = "csvlens";
    wsl.nixpkgs = "csvlens";
  };
}
