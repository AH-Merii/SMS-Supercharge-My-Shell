# Claude Code from nixpkgs, so the binary moves with the lock file like every other tool
# rather than updating itself underneath the settings this directory ships. The settings file
# is live and writable: Claude Code rewrites it as preferences change in the session.
{
  tier = "shell";
  install = {
    linux.nixpkgs = "claude-code";
    darwin.nixpkgs = "claude-code";
    wsl.nixpkgs = "claude-code";
  };
}
