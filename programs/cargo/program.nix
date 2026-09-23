# Separate from rustc because nixpkgs ships cargo as its own derivation.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "cargo";
    darwin.nixpkgs = "cargo";
    wsl.nixpkgs = "cargo";
  };
}
