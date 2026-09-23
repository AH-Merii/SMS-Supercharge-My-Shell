# mise stays on every machine to honour a project's pin, and owns nothing else
{
  tier = "shell";
  install = {
    linux.nixpkgs = "mise";
    darwin.nixpkgs = "mise";
    wsl.nixpkgs = "mise";
  };
}
