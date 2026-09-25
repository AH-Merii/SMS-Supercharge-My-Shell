{
  tier = "shell";
  install = {
    linux.nixpkgs = "shellcheck";
    darwin.nixpkgs = "shellcheck";
    wsl.nixpkgs = "shellcheck";
  };
}
