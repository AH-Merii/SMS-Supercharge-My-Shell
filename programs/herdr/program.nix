# nixpkgs carries herdr under its own name, so the aqua backend and the pin
# against the abandoned upstream org are no longer needed
{
  tier = "shell";
  install = {
    linux.nixpkgs = "herdr";
    darwin.nixpkgs = "herdr";
    wsl.nixpkgs = "herdr";
  };
}
