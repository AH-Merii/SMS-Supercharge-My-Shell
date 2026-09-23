# One home-manager configuration per tier-and-platform pair, all from this lock file.
#
#   nix build --impure .#homeConfigurations.shell-linux.activationPackage   # build only
#   nix flake check --impure                                                 # build + assertions
#   nix run --impure .#tiers                                                 # the computed view
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
      inherit (nixpkgs) lib;

      inherit (import ./nix/vocabulary.nix) tiers platforms;

      # Which nixpkgs system each platform builds for. WSL2 is Linux.
      systemOf = { linux = "x86_64-linux"; darwin = "aarch64-darwin"; wsl = "x86_64-linux"; };

      # The pairs that exist. Desktop on macOS waits for nix-darwin, and WSL2 has no
      # graphical session of ours.
      pairs = [
        { tier = "shell"; platform = "linux"; }
        { tier = "desktop"; platform = "linux"; }
        { tier = "shell"; platform = "darwin"; }
        { tier = "shell"; platform = "wsl"; }
      ];
      nameOf = pair: "${pair.tier}-${pair.platform}";

      configuration = { tier, platform }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${systemOf.${platform}};
          modules = [ ./nix/home.nix { sms = { inherit tier platform; }; } ];
        };

      forAllSystems = f:
        lib.genAttrs (lib.unique (map (pair: systemOf.${pair.platform}) pairs))
          (system: f system nixpkgs.legacyPackages.${system});
    in {
      homeConfigurations =
        lib.listToAttrs (map (pair: lib.nameValuePair (nameOf pair) (configuration pair)) pairs);

      packages = forAllSystems (_: pkgs: {
        tiers = pkgs.callPackage ./nix/tiers.nix { } {
          inherit tiers platforms;
          configurations = self.homeConfigurations;
        };
      });

      # A configuration only builds on its own system, so each system checks the pairs that
      # are its own, and so does any check that builds a configuration's files. The
      # assertions read evaluated configurations and run anywhere.
      checks = forAllSystems (system: pkgs:
        let
          builds = lib.listToAttrs (map
            (pair: lib.nameValuePair (nameOf pair) self.homeConfigurations.${nameOf pair}.activationPackage)
            (lib.filter (pair: systemOf.${pair.platform} == system) pairs));

          onLinux = lib.optionalAttrs (system == systemOf.linux) {
            bat-links-live = pkgs.callPackage ./nix/checks/links-live.nix {
              home = self.homeConfigurations.shell-linux;
            };
          };

          # One list check per configuration and source, so a source added to a declaration
          # is checked without a name being written here.
          distroLists = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList
            (name: home: map
              (source: lib.nameValuePair "${source}-list-${name}"
                (pkgs.callPackage ./nix/checks/distro-list.nix {
                  inherit source;
                  configuration = home;
                  programsDir = ./programs;
                  platformsDir = ./platforms;
                }))
              (lib.attrNames home.config.sms.distro))
            self.homeConfigurations));

          # Every platform that has both tiers; Linux is the only one so far.
          containsShell = lib.listToAttrs (map
            (platform: lib.nameValuePair "desktop-${platform}-contains-shell"
              (pkgs.callPackage ./nix/checks/desktop-contains-shell.nix {
                shell = self.homeConfigurations."shell-${platform}";
                desktop = self.homeConfigurations."desktop-${platform}";
              }))
            (lib.filter (platform: self.homeConfigurations ? "desktop-${platform}") platforms));
        in builds // onLinux // distroLists // containsShell // {
          declared-membership = pkgs.callPackage ./nix/checks/declared-membership.nix {
            configurations = self.homeConfigurations;
            programsDir = ./programs;
          };
        });
    };
}
