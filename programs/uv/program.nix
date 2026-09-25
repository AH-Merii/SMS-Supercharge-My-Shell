# the Python runtime too: uv manages the interpreters, so there is no python program
{
  tier = "shell";
  install = {
    linux.nixpkgs = "uv";
    darwin.nixpkgs = "uv";
    wsl.nixpkgs = "uv";
  };
}
