# Desktop is Shell and more. Everything the Shell configuration on a platform contains, the
# Desktop configuration on that platform contains too: the same programs, and the same files
# under ~. A Desktop machine is never a Shell machine with something missing.
{ lib, runCommand, shell, desktop }:
let
  lacking = kind: got: wanted: map (name: "${kind} ${name}") (lib.subtractLists got wanted);

  missing =
    lacking "program" (lib.attrNames desktop.config.sms.programs) (lib.attrNames shell.config.sms.programs)
    ++ lacking "file" (lib.attrNames desktop.config.home.file) (lib.attrNames shell.config.home.file);

  name = "desktop-${shell.config.sms.platform}-contains-shell";
in
runCommand name { } ''
  ${lib.concatMapStrings (m: "echo 'missing from Desktop: ${m}'\n") missing}
  ${lib.optionalString (missing != [ ]) "exit 1"}
  touch "$out"
''
