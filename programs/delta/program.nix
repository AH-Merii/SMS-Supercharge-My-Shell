# git's pager, configured from programs/git; it ships no config tree of its own
{
  tier = "shell";
  install = {
    linux.nixpkgs = "delta";
    darwin.nixpkgs = "delta";
    wsl.nixpkgs = "delta";
  };
}
