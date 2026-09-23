# nixpkgs' unsuffixed nodejs is the current LTS, which is what mise pinned before this.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "nodejs";
    darwin.nixpkgs = "nodejs";
    wsl.nixpkgs = "nodejs";
  };
}
