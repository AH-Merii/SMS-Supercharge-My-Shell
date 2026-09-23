# The linker's refusals, which linker.nix explains. The one check that runs the linker rather
# than re-deriving what it should have done, because the refusal is the thing under test.
# tryEval reports that evaluation failed but not what it said, so what the messages name is
# fixed by the linker's code and not asserted here.
{ lib, pkgs, runCommand, programsDir, platformsDir, fixturesDir, checkout }:
let
  link = args: import ../linker.nix {
    inherit lib pkgs;
    # The linker never forces a link's target on the paths under test, and the refusals must
    # not depend on home-manager, so the identity function stands in for the real helper.
    mkOutOfStoreSymlink = target: target;
    # No refusal depends on the tier or platform asked for, so one pair stands for all.
  } ({
    tier = "shell";
    platform = "linux";
    inherit checkout programsDir platformsDir;
  } // args);

  # deepSeq, because the refusals are inside lazy attributes that tryEval alone would not force.
  verdict = wanted: what: value:
    let attempt = builtins.tryEval (builtins.deepSeq value value);
    in lib.optional (attempt.success != wanted)
      "${what} was ${if attempt.success then "accepted" else "refused"} and must not be";

  refused = verdict false;
  accepted = verdict true;

  failures =
    refused "a path claimed by two programs"
      (link { programsDir = fixturesDir + "/collision"; }).files
    ++ refused "a checkout that does not exist"
      (link { checkout = "/nowhere/no-such-checkout"; }).files
    ++ refused "a checkout that holds no programs/"
      (link { checkout = toString (fixturesDir + "/not-a-checkout"); }).files
    ++ accepted "this checkout" (link { }).files;
in
runCommand "linker-refusals"
{
  failures = lib.concatMapStrings (line: line + "\n") failures;
  passAsFile = [ "failures" ];
} ''
  if [ -s "$failuresPath" ]; then cat "$failuresPath"; exit 1; fi
  touch "$out"
''
