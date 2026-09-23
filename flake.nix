# One home-manager configuration per tier-and-platform pair, all from this lock file.
#
#   nix build --impure .#homeConfigurations.shell-linux.activationPackage   # build only
#   nix flake check --impure                                                 # build + assertions
#
# --impure because the username and home directory are read from the environment; nothing
# person-specific is committed. SMS_CHECKOUT, when set, is where the live links point
# instead of the checkout under ~ (a worktree under test, say).
{
  description = "SMS Supercharge-My-Shell: one tier on one platform, from one lock file";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      configuration = { tier, platform }:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./nix/home.nix { sms = { inherit tier platform; }; } ];
        };
    in {
      homeConfigurations.shell-linux = configuration { tier = "shell"; platform = "linux"; };

      checks.${system} = {
        shell-linux = self.homeConfigurations.shell-linux.activationPackage;
        bat-links-live = pkgs.callPackage ./nix/checks/links-live.nix {
          home = self.homeConfigurations.shell-linux;
        };
      };
    };
}
