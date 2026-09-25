# the shell itself; the tier is named after it
{
  tier = "shell";
  install = {
    linux.nixpkgs = "fish";
    darwin.nixpkgs = "fish";
    wsl.nixpkgs = "fish";
  };
}
