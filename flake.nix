# One home-manager configuration per tier-and-platform pair, all from this lock file.
#
#   nix build --impure .#homeConfigurations.shell-linux.activationPackage   # build only
#   nix flake check --impure                                                 # build + assertions
#   nix run --impure .#tiers                                                 # the computed view
#
# --impure because the username and home directory are read from the environment; nothing
# person-specific is committed. Anywhere the clone is not at ~/SMS-Supercharge-My-Shell --
# CI, a container, a worktree -- SMS_CHECKOUT has to say where it is, or the build refuses
# rather than pointing the live links at a path that is not there:
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

      # A predicate rather than allowUnfree, so a second unfree package cannot arrive without
      # a line here saying so.
      allowedUnfree = [ "claude-code" ];
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: lib.elem (lib.getName pkg) allowedUnfree;
      };

      # What a platform directory adds beyond its lists: a home-manager module per tier, for
      # the tiers it has one for. Desktop is Shell and more, so Desktop takes the Shell one too.
      platformModules = { tier, platform }:
        lib.filter builtins.pathExists
          (map (t: ./platforms + "/${platform}/${t}.nix")
            (if tier == "desktop" then [ "shell" "desktop" ] else [ "shell" ]));

      configuration = { tier, platform }@pair:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor systemOf.${platform};
          modules = [ ./nix/home.nix { sms = { inherit tier platform; }; } ] ++ platformModules pair;
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

          fileChecks = lib.listToAttrs (map
            (pair: lib.nameValuePair "files-live-and-applied-${nameOf pair}"
              (pkgs.callPackage ./nix/checks/files-live-and-applied.nix {
                configuration = self.homeConfigurations.${nameOf pair};
                programsDir = ./programs;
              }))
            ours);

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

          # Linux's alone: environment.d is systemd's, and Desktop exists nowhere else yet.
          sessions = lib.listToAttrs (map
            (pair: lib.nameValuePair "${nameOf pair}-session"
              (pkgs.callPackage ./nix/checks/desktop-session.nix {
                configuration = self.homeConfigurations.${nameOf pair};
                programsDir = ./programs;
              }))
            (lib.filter (pair: pair.tier == "desktop" && pair.platform == "linux") ours));

          # Linux's alone as well: niri is the Desktop compositor there and nowhere else yet.
          niriIncludes = lib.listToAttrs (map
            (pair: lib.nameValuePair "${nameOf pair}-niri-includes"
              (pkgs.callPackage ./nix/checks/niri-includes.nix {
                configuration = self.homeConfigurations.${nameOf pair};
                programsDir = ./programs;
              }))
            (lib.filter (pair: pair.tier == "desktop" && pair.platform == "linux") ours));

          containsShell = lib.listToAttrs (map
            (platform: lib.nameValuePair "desktop-${platform}-contains-shell"
              (pkgs.callPackage ./nix/checks/desktop-contains-shell.nix {
                shell = self.homeConfigurations."shell-${platform}";
                desktop = self.homeConfigurations."desktop-${platform}";
              }))
            (lib.filter (platform: self.homeConfigurations ? "desktop-${platform}") platforms));
        in builds // fileChecks // runtimeChecks // distroLists // sessions // niriIncludes // containsShell // {
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

          # Not one of the pairs either: the prompt is the same shell on every system.
          prompt-never-waits-on-git = pkgs.callPackage ./nix/checks/prompt-never-waits-on-git.nix {
            programsDir = ./programs;
          };
        });
    };
}
