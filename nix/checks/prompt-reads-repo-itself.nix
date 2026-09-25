# The prompt reads the repository itself. starship's git modules use its embedded reader
# unless the git config makes them run the git binary (core.fsmonitor is the one setting that
# does), and a git process at every prompt is what "Executing command git timed out" comes
# from: git's first call in a repo starts the fsmonitor daemon and waits for it, which on a
# cold disk is longer than the prompt's command_timeout (#144). The git on PATH here records
# what it was asked before the real one answers.
{ lib, runCommand, runtimeShell, starship, git, programsDir }:
runCommand "prompt-reads-repo-itself"
{
  nativeBuildInputs = [ starship git ];
  starshipConfig = programsDir + "/starship/.config/starship/starship.toml";
  gitConfigDir = programsDir + "/git/.config/git";
} ''
  export HOME=$TMPDIR/home XDG_CONFIG_HOME=$TMPDIR/home/.config XDG_CACHE_HOME=$TMPDIR/home/.cache
  mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
  cp -r "$gitConfigDir" "$XDG_CONFIG_HOME/git"
  export STARSHIP_CONFIG=$starshipConfig

  # First on PATH, since starship finds git by name.
  mkdir -p "$TMPDIR/bin"
  cat > "$TMPDIR/bin/git" <<SHIM
  #!${runtimeShell}
  printf '%s\n' "\$*" >> "$TMPDIR/git-calls"
  exec ${lib.getExe git} "\$@"
  SHIM
  chmod +x "$TMPDIR/bin/git"
  export PATH=$TMPDIR/bin:$PATH

  # Signing is the shipped config's default and has no key here.
  mkdir "$TMPDIR/repo" && cd "$TMPDIR/repo"
  git init -q -b main
  echo one > tracked && git add tracked
  git -c commit.gpgsign=false -c user.name=t -c user.email=t@t commit -qm one
  echo two > tracked
  touch untracked

  : > "$TMPDIR/git-calls"
  starship prompt > "$TMPDIR/prompt" 2> "$TMPDIR/stderr"
  starship module git_status > "$TMPDIR/status" 2>> "$TMPDIR/stderr"
  plain=$(sed 's/\x1b\[[0-9;]*[A-Za-z]//g' "$TMPDIR/prompt")
  status=$(sed 's/\x1b\[[0-9;]*[A-Za-z]//g' "$TMPDIR/status")

  failed=0
  fail() { echo "$1"; failed=1; }
  # The warning goes to stderr and to a session log under the cache; the log alone would do,
  # but stderr is where a user would see it.
  grep -rq 'timed out' "$TMPDIR/stderr" "$XDG_CACHE_HOME" && fail "starship warned that a command timed out"
  case "$plain" in *main*) ;; *) fail "the prompt does not name the branch: $plain" ;; esac
  # Nothing but the edit and the new file can show here: the fixture has no stash, no
  # upstream and no conflict.
  [ -n "$status" ] || fail "git_status shows nothing for a dirty tree"
  case "$plain" in *"$status"*) ;; *) fail "the prompt does not carry the dirty state: $plain" ;; esac
  grep -Eq '(^| )(status|diff)( |$)' "$TMPDIR/git-calls" \
    && fail "a git status or diff process ran at the prompt; git was asked:" && cat "$TMPDIR/git-calls"
  if [ "$failed" = 1 ]; then echo "--- stderr"; cat "$TMPDIR/stderr"; exit 1; fi
  touch "$out"
''
