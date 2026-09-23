# context-bar.sh is applied rather than live: unlike settings.json, which ccstatusline's TUI
# rewrites, the script only ever changes here, so the store copy rolls back with the package
# that runs it.
{
  tier = "shell";
  applied = [ ".config/ccstatusline/context-bar.sh" ];
  install = {
    linux.repo = "ccstatusline";
    darwin.repo = "ccstatusline";
    wsl.repo = "ccstatusline";
  };
}
