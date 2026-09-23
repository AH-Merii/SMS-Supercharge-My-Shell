# ccstatusline is not in nixpkgs, so the repo packages it rather than reopening the question
# of a second package manager. npm publishes it as one bundled ESM file with no dependencies
# at runtime, so there is nothing to resolve: unpack the tarball, keep dist/, and hand the
# entry point to node.
#
# Bumping it is by hand, and deliberately so -- the status line repaints on every keystroke's
# worth of work, and `npx ccstatusline@latest` re-resolving the package each time is the
# ~430ms this pin exists to avoid. To move it: change `version`, set `hash` to
# lib.fakeHash, build, and copy the hash the failure prints.
{ lib, stdenvNoCC, fetchurl, nodejs, makeWrapper }:
let
  version = "2.2.28";
in
stdenvNoCC.mkDerivation {
  pname = "ccstatusline";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${version}.tgz";
    hash = "sha256-CJx9sTPvDFDwKszpDBvkGO/RbWZ0bnFt2VkTVRxY1dI=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/ccstatusline
    cp -r dist $out/lib/ccstatusline/
    makeWrapper ${lib.getExe nodejs} $out/bin/ccstatusline \
      --add-flags $out/lib/ccstatusline/dist/ccstatusline.js
    runHook postInstall
  '';

  meta = {
    description = "Status line for Claude Code";
    homepage = "https://github.com/sirmalloc/ccstatusline";
    license = lib.licenses.mit;
    mainProgram = "ccstatusline";
  };
}
