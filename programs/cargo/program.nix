# Its own program because nixpkgs ships it as its own derivation: rustc does not bring cargo,
# and one declaration names one package.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "cargo";
    darwin.nixpkgs = "cargo";
    wsl.nixpkgs = "cargo";
  };
}
