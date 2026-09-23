# The home-manager module every configuration is built from: which tier on which platform,
# where the checkout is, and whose home this is. What the declarations computed to -- the
# programs this configuration contains and the lists the distro installs -- is read back off
# the built configuration, by the flake checks and by the tiers task.
{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
  vocabulary = import ./vocabulary.nix;

  # Read at evaluation time, so every command that evaluates a configuration passes --impure.
  env = name:
    let value = builtins.getEnv name;
    in if value == "" then throw "${name} is not set: evaluate with --impure" else value;
  home = env "HOME";
  # Unset, the usual location under ~ applies.
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
    tier = mkOption { type = types.enum vocabulary.tiers; };
    platform = mkOption { type = types.enum vocabulary.platforms; };
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
          tier = mkOption { type = types.enum vocabulary.tiers; };
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

    # Published so a config that cannot be generated -- the Claude settings, which Claude Code
    # rewrites -- can name the checkout without writing a path down.
    #
    # One name for both directions, which pins: this is the same variable the build reads, so a
    # switch made against a worktree exports it to every later shell, whose builds then target
    # that worktree again. Coming back is deliberate -- `SMS_CHECKOUT=<checkout>` on the switch
    # that moves it, or `set -e SMS_CHECKOUT` first.
    home.sessionVariables.SMS_CHECKOUT = config.sms.checkout;

    sms = { inherit (linked) programs distro; };
  };
}
