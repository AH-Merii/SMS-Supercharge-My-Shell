# `op`, the CLI the desktop app unlocks; Desktop because it is nothing without that app. The
# AUR package is community-maintained, unlike 1password beside it, but its PKGBUILD automates
# 1Password's documented manual install -- the same CDN URL, the same `gpg --verify op.sig
# op`, the same signing key -- so trust rests on 1Password's signature rather than on the
# packager. Still skim the PKGBUILD diff the AUR helper shows. The macOS cask is declared and
# not wired until the nix-darwin phase.
{
  tier = "desktop";
  install = {
    linux.aur = "1password-cli";
    darwin.brew = "1password-cli";
  };
}
