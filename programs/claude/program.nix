# From nixpkgs so the binary moves with the lock file rather than updating itself underneath
# the settings this directory ships, which stay live because Claude Code rewrites them.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "claude-code";
    darwin.nixpkgs = "claude-code";
    wsl.nixpkgs = "claude-code";
  };
}
