# Not in nixpkgs. npm publishes it as one bundled ESM file with no runtime dependencies, so
# there is nothing to resolve: unpack the tarball, keep dist/, hand the entry point to node.
#
# Pinned rather than `npx ccstatusline@latest`, which re-resolves the package on every repaint
# -- the ~430ms this exists to avoid. To bump: change `version`, set `hash` to lib.fakeHash,
# build, and copy the hash the failure prints.
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
