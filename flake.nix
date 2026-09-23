# One home-manager configuration per tier-and-platform pair, all from this lock file.
#
#   nix build --impure .#homeConfigurations.shell-linux.activationPackage   # build only
#   nix flake check --impure                                                 # build + assertions
#   nix run --impure .#tiers                                                 # the computed view
#
# --impure because the username and home directory are read from the environment; nothing
# person-specific is committed. SMS_CHECKOUT, when set, is where the live links point
# instead of the checkout under ~ (a worktree under test, say).
#
# Anywhere the clone is not at ~/SMS-Supercharge-My-Shell -- CI, a container, a worktree --
# SMS_CHECKOUT has to say so, or every configuration refuses to build rather than pointing
# the live links at a path that is not there:
#
#   SMS_CHECKOUT=$PWD nix flake check --impure
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

      # nixpkgs refuses an unfree package by default, and one program is unfree. A predicate
      # naming it, rather than allowUnfree, so that the licence is accepted for this package
      # and a second unfree one cannot arrive without a line here saying so.
      allowedUnfree = [ "claude-code" ];
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) allowedUnfree;
      };

      configuration = { tier, platform }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor systemOf.${platform};
          modules = [ ./nix/home.nix { sms = { inherit tier platform; }; } ];
        };

      forAllSystems = f:
        lib.genAttrs (lib.unique (map (pair: systemOf.${pair.platform}) pairs))
          (system: f system (pkgsFor system));
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
          ours = lib.filter (pair: systemOf.${pair.platform} == system) pairs;

          builds = lib.listToAttrs (map
            (pair: lib.nameValuePair (nameOf pair) self.homeConfigurations.${nameOf pair}.activationPackage)
            ours);

          # Builds a configuration's files, so only the pairs of this system.
          fileChecks = lib.listToAttrs (map
            (pair: lib.nameValuePair "files-live-and-applied-${nameOf pair}"
              (pkgs.callPackage ./nix/checks/files-live-and-applied.nix {
                configuration = self.homeConfigurations.${nameOf pair};
                programsDir = ./programs;
              }))
            ours);

          # Reads a configuration's package set, which only resolves on its own system.
          runtimeChecks = lib.listToAttrs (map
            (pair: lib.nameValuePair "runtimes-and-pins-${nameOf pair}"
              (pkgs.callPackage ./nix/checks/runtimes-and-pins.nix {
                configuration = self.homeConfigurations.${nameOf pair};
                programsDir = ./programs;
              }))
            ours);

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
        in builds // fileChecks // runtimeChecks // distroLists // containsShell // {
          declared-membership = pkgs.callPackage ./nix/checks/declared-membership.nix {
            configurations = self.homeConfigurations;
            programsDir = ./programs;
          };

          # Not one of the pairs: a unit test of the linker's refusals, which are the same
          # whichever tier and platform it is asked about, so it runs on every system.
          linker-refusals = pkgs.callPackage ./nix/checks/linker-refusals.nix {
            programsDir = ./programs;
            platformsDir = ./platforms;
            fixturesDir = ./nix/checks/fixtures;
            inherit (self.homeConfigurations.shell-linux.config.sms) checkout;
          };
        });
    };
}
