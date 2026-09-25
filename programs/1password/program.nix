# 1Password keeps nothing we would edit, so the declaration is the whole program. The AUR
# package is 1Password's own, unlike the community-maintained CLI beside it, which is a
# program of its own. The macOS cask is declared and not wired until the nix-darwin phase.
{
  tier = "desktop";
  install = {
    linux.aur = "1password";
    darwin.brew = "1password";
  };
}
