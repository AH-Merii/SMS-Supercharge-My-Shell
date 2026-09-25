# The prompt is usable before git answers (#144): an interactive fish on a pty, with the
# shipped configs whole, against a git made slow.
{ lib, runCommand, runtimeShell, fish, starship, git, python3, programsDir }:
runCommand "prompt-never-waits-on-git"
{
  nativeBuildInputs = [ fish starship git python3 ];
  fishConfig = programsDir + "/fish/.config/fish";
  starshipConfig = programsDir + "/starship/.config/starship";
  gitConfig = programsDir + "/git/.config/git";
  driver = ./prompt-never-waits-on-git.py;
} ''
  export HOME=$TMPDIR/home XDG_CONFIG_HOME=$TMPDIR/home/.config
  mkdir -p "$XDG_CONFIG_HOME"
  cp -r "$fishConfig" "$XDG_CONFIG_HOME/fish"
  cp -r "$starshipConfig" "$XDG_CONFIG_HOME/starship"
  cp -r "$gitConfig" "$XDG_CONFIG_HOME/git"
  chmod -R u+w "$XDG_CONFIG_HOME"
  export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  # Signing is the shipped config's default and has no key here.
  git config -f "$XDG_CONFIG_HOME/git/config" commit.gpgsign false
  git config -f "$XDG_CONFIG_HOME/git/config" user.name t
  git config -f "$XDG_CONFIG_HOME/git/config" user.email t@t

  # First on PATH, since starship finds git by name.
  mkdir -p "$TMPDIR/bin"
  export GIT_CALLS=$TMPDIR/git-calls
  cat > "$TMPDIR/bin/git" <<SHIM
  #!${runtimeShell}
  printf '%s\n' "\$*" >> "$GIT_CALLS"
  case " \$* " in *" status "*|*" diff "*) sleep 1.5 ;; esac
  exec ${lib.getExe git} "\$@"
  SHIM
  chmod +x "$TMPDIR/bin/git"
  export PATH=$TMPDIR/bin:$PATH

  mkdir "$TMPDIR/repo" && cd "$TMPDIR/repo"
  git init -q -b main
  echo one > tracked && git add tracked && git commit -qm one
  echo two > tracked
  touch untracked

  # What the dirty tree renders as, from the module itself.
  dirty=$(starship module git_status | sed 's/\x1b\[[0-9;]*[A-Za-z]//g')
  [ -n "$dirty" ] || { echo "git_status shows nothing for a dirty tree"; exit 1; }

  python3 "$driver" "$dirty" && touch "$out"
''
