# A runtime is an ordinary tool: one version for the machine, from the same lock file as
# everything else. A project that needs another one pins it, and mise honours the pin inside
# that project only. nixpkgs' unsuffixed nodejs is the current LTS, which is what mise asked for.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "nodejs";
    darwin.nixpkgs = "nodejs";
    wsl.nixpkgs = "nodejs";
  };
}
