{
  tier = "shell";
  install = {
    linux.nixpkgs = "jq";
    darwin.nixpkgs = "jq";
    wsl.nixpkgs = "jq";
  };
}
