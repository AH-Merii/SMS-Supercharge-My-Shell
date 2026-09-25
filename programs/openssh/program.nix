# A desktop Arch box gets ssh from gcr's dependency; a shell-only one, macOS and WSL do not.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "openssh";
    darwin.nixpkgs = "openssh";
    wsl.nixpkgs = "openssh";
  };
}
