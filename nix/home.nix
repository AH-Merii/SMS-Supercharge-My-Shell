# The home-manager module every configuration is built from: which tier on which platform,
# where the checkout is, and whose home this is. What the declarations computed to -- the
# programs this configuration contains and the lists the distro installs -- is read back off
# the built configuration, by the flake checks and by the tiers task.
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;

  # Read at evaluation time, so every command that evaluates a configuration passes --impure.
  env = name:
    let value = builtins.getEnv name;
    in if value == "" then throw "${name} is not set: evaluate with --impure" else value;
  home = env "HOME";
  # SMS_CHECKOUT points a build at a checkout other than the one under ~, such as a
  # worktree while a branch is being tested; unset, the usual location applies.
  checkoutEnv = builtins.getEnv "SMS_CHECKOUT";

  linked = import ./linker.nix {
    inherit lib pkgs;
    inherit (config.lib.file) mkOutOfStoreSymlink;
  } {
    inherit (config.sms) tier platform checkout;
    programsDir = ../programs;
    platformsDir = ../platforms;
  };

in {
  options.sms = {
    tier = mkOption { type = types.enum [ "shell" "desktop" ]; };
    platform = mkOption { type = types.enum [ "linux" "darwin" "wsl" ]; };
    checkout = mkOption {
      # A string, never a path: a path would copy the checkout into the store and every
      # live file would point at the copy.
      type = types.str;
      default = if checkoutEnv != "" then checkoutEnv else "${home}/SMS-Supercharge-My-Shell";
      description = "Where the repo is checked out; every live file links into it.";
    };

    programs = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          tier = mkOption { type = types.enum [ "shell" "desktop" ]; };
          source = mkOption { type = types.str; };
          package = mkOption { type = types.str; };
        };
      });
      readOnly = true;
      description = "The programs this configuration contains, and where each is installed from.";
    };
    distro = mkOption {
      type = types.attrsOf (types.listOf types.str);
      readOnly = true;
      description = "What this configuration expects the distro to install, keyed by source.";
    };
  };

  config = {
    home.username = env "USER";
    home.homeDirectory = home;
    home.stateVersion = "25.05";
    home.file = linked.files;
    home.packages = linked.packages;

    sms = { inherit (linked) programs distro; };
  };
}
