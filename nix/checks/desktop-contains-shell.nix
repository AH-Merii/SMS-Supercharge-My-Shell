# Desktop is Shell and more. Everything the Shell configuration on a platform contains, the
# Desktop configuration on that platform contains too: the same programs, and the same files
# under ~. A Desktop machine is never a Shell machine with something missing.
{ lib, runCommand, shell, desktop }:
let
  lacking = kind: inDesktop: inShell:
    map (name: "${kind} ${name}") (lib.subtractLists inDesktop inShell);

  absent =
    lacking "program" (lib.attrNames desktop.config.sms.programs) (lib.attrNames shell.config.sms.programs)
    ++ lacking "file" (lib.attrNames desktop.config.home.file) (lib.attrNames shell.config.home.file);

  name = "desktop-${shell.config.sms.platform}-contains-shell";
in
# The names come from directory listings, so they go to the builder as a file rather than as
# shell words: one carrying a quote would otherwise end the string it was interpolated into.
runCommand name
{
  absent = lib.concatMapStrings (line: line + "\n") absent;
  passAsFile = [ "absent" ];
} ''
  if [ -s "$absentPath" ]; then
    echo "Desktop must contain everything Shell does, and lacks:"
    cat "$absentPath"
    exit 1
  fi
  touch "$out"
''
