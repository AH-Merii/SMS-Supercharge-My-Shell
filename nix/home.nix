# The home-manager module every configuration is built from: which tier on which platform,
# where the checkout is, and whose home this is.
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

  programs = import ./linker.nix {
    inherit lib pkgs;
    inherit (config.lib.file) mkOutOfStoreSymlink;
  } {
    inherit (config.sms) tier platform checkout;
    programsDir = ../programs;
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
  };

  config = {
    home.username = env "USER";
    home.homeDirectory = home;
    home.stateVersion = "25.05";
    home.file = programs.files;
    home.packages = programs.packages;
  };
}
