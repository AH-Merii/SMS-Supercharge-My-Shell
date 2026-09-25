# The platforms bat exists on are the keys of `install`; each says how it is installed there.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "bat";
    darwin.nixpkgs = "bat";
    wsl.nixpkgs = "bat";
  };
}
