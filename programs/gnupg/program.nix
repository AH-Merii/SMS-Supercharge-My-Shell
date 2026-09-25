# Arch has gpg whatever we say, since pacman depends on it; macOS and WSL do not.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "gnupg";
    darwin.nixpkgs = "gnupg";
    wsl.nixpkgs = "gnupg";
  };
}
