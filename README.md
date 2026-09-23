# SMS Supercharge-My-Shell

My working/development environment, carried onto any machine I am handed: a Linux desktop,
a Mac, a Windows box through WSL2, or a bare server. Every tool comes from one committed lock
file through Nix home-manager; every config is a plain file in this checkout that `~` reaches
through a link, so an edit is seen by the program at once.

The vocabulary used below (tier, platform, program, live file, applied file, and the rest)
is defined in `CONTEXT.md`. The reasons behind the shape are in `docs/adr/`.

## The shape

```
programs/<name>/          one directory per program
  program.nix             its declaration: tier, and how it is installed on each platform
  .config/...             its config tree, shaped like ~, linked live into the home
  package.nix             only for a program nixpkgs does not carry
platforms/<platform>/
  platform.nix            packages the distro installs that belong to no one program
  <tier>.nix              a home-manager module for that tier on that platform, if any
nix/                      the linker, the module and the flake checks
flake.nix, flake.lock     the configurations and the versions of everything in them
mise-tasks/               the front door: check, switch, update, setup, pacman, tiers
bootstrap.sh              a Fresh machine, from nothing to setup
```

Everything a machine has is placed by answering four questions: which program it belongs to,
which tier that program is in, which platforms it exists on, and where it is installed from
on each.

**A program** is the unit. `programs/fish/` holds fish's config tree and a declaration:

```nix
{
  tier = "shell";
  install = {
    linux.nixpkgs = "fish";
    darwin.nixpkgs = "fish";
    wsl.nixpkgs = "fish";
  };
}
```

The tier says which machines get it. The `install` set says on which platforms it exists at
all, and for each one the install source it comes from and the package name there. A
platform not named means the program is absent on that platform, config tree included.

**A tier** is what a machine gets. `shell` is the layer every machine has in common: fish,
neovim, tmux, git and the command-line tools. `desktop` is the graphical session on top of it,
so a Desktop machine has every Shell program too. What a tier contains is never written down
as a list; it is computed from the declarations, and `mise run tiers` prints it.

**A platform** is how a program is installed and which ones exist there: `linux`, `darwin` or
`wsl`. The platform directory holds what belongs to the platform rather than to any program:
on Linux, the session stack pacman installs and the fonts, cursor and session environment
home-manager adds for Desktop. macOS and WSL2 are present and empty.

**An install source** is where a program comes from on one platform. `nixpkgs` and `repo`
(a `package.nix` in the program's own directory) are installed by the configuration itself.
`pacman` and `aur` are handed to the distro: the configuration computes the list and you run
the install. `brew` may be declared for macOS but nothing reads it yet.

A **configuration** is one tier on one platform. Four exist: `shell-linux`, `desktop-linux`,
`shell-darwin` and `shell-wsl`. Desktop on macOS waits for nix-darwin, and WSL2 has no
graphical session of ours. The username and home directory are read from the environment
when a configuration is built, so nothing in the repo names a person or a machine.

Two rules cut across all of this. Every tool on a machine, language runtimes included, is
installed by the configuration from `flake.lock`; mise is kept only to honour a project's own
pin, and its global config is deliberately empty. And every file a program ships is live, a
link into the checkout, unless the program names it as applied, in which case a switch copies
it and the copy rolls back together with the packages.

## Setting up a machine

### A Fresh machine

You need `curl` and, on Linux, `sudo`. Nothing else. One command takes the machine from
nothing to set up:

```sh
curl -fsSL https://raw.githubusercontent.com/AH-Merii/SMS-Supercharge-My-Shell/main/bootstrap.sh | sh
```

On a Linux desktop say `sh -s -- --tier desktop` instead of `sh`. The script does three
things, each skipped when already done, so it is safe to run again:

1. Installs Nix with the Determinate installer, unless `nix` is already there. That sets up
   the multi-user daemon, turns flakes on and leaves a one-command uninstall behind. The
   installer asks its own question.
2. Clones the repo to `~/SMS-Supercharge-My-Shell`, unless it is already there.
3. Runs `mise run setup` for the tier, in a shell that borrows git, mise and bash from nixpkgs
   because the machine has none of them yet. After the first switch it has all three from the
   configuration, and that shell is never needed again.

`setup` builds the configuration and shows one plan: what the switch will do to this home
(packages, links, and any file in the way with the name it will be backed up under), and on
Linux with pacman the derived pacman and AUR lists against what is installed, and on a
Desktop the login screen. One question, then every step runs in order: the switch, pacman,
the greeter, the Claude memories. The greeter writes root's files and asks for your password
itself, whatever was answered and whatever pacman left cached. `-y` (or `SMS_YES=1`) answers
every question yes, for a run nobody is watching; the greeter then stops rather than run
unattended.

The same steps by hand, for a machine where the one command is not wanted:

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
# open a new shell so nix is on the PATH
nix shell nixpkgs#git nixpkgs#mise nixpkgs#bash
git clone https://github.com/AH-Merii/SMS-Supercharge-My-Shell.git ~/SMS-Supercharge-My-Shell
cd ~/SMS-Supercharge-My-Shell
mise trust
mise run setup --tier shell
exit
```

Or, instead of `setup`, the steps one at a time, each with its own preview and question and
all with the same `--tier`: `mise run switch --tier desktop`, then on Linux with pacman
`mise run pacman --tier desktop`, then on a Desktop `mise run greeter`, then `mise run
memory`. The platform is detected from the machine either way.

**What the distro installs.** On Linux with pacman, the configuration computes what pacman
and the AUR are expected to install: for Shell it is `base-devel` alone, which building
from the AUR needs; for Desktop it adds the compositor, the bar, the greeter and the portals,
which pacman keeps so they move with the drivers, and 1Password with its CLI from the AUR.
`mise run pacman --tier desktop` previews the two lists against what is installed and asks
once; `mise run tiers` shows the same lists, one row per program plus a `platforms/linux`
row for what belongs to no program. paru installs the AUR list: CachyOS ships it, and on
plain Arch it is built from the AUR first, which is what `base-devel` is for; without it the
AUR names are printed for you to install by hand. A Linux without pacman (Debian, say) has
nothing to install here.

**The login screen** is root's and stays a separate step that asks for sudo, run by `setup`
on a Desktop or by hand as `mise run greeter`. It installs the greetd config, switches the
display manager from sddm and syncs Noctalia's look into the greeter. Reboot to log in
through it. Run before the pacman step, it stops: the packages it configures are not there
yet.

**Then, the pieces the configuration does not own.** Make fish the login shell first: it
lives in the Nix profile, which the login database does not know about, and `setup` prints
these two lines when it finishes:

```sh
echo "$HOME/.nix-profile/bin/fish" | sudo tee -a /etc/shells
chsh -s "$HOME/.nix-profile/bin/fish"
```

Log in again. fish puts the Nix profile on the PATH itself, so a login shell, a `fish -c`
and a program spawned by the compositor all see the same tools. Fish and tmux plugins are
fetched by their own managers, and git's identity and signing key are yours, never
committed:

```sh
mise run plugins
ggh
```

fish reminds you about `ggh` until the identity is set. `mise run memory` links the portable
Claude Code memories into this checkout's project directory; `setup` has run it already.

### An Existing machine

A machine that already has some of these programs, or its own files at the paths the
configuration manages, is set up the same way, by the one command or by hand. The preview
before the switch lists every file in the way and the name it will be backed up under
(`<path>.bak`, or a timestamped suffix if that name is taken); nothing is lost. Software installed by other means is left alone: the
Nix profile goes in front of it on the PATH and the two coexist.

One case is refused rather than backed up. home-manager backs up files and never links, so a
link at a managed path that does not already point at the same content stops the switch with
the offending paths listed. Move them aside and run the switch again.

### A Set-up machine

Catching up is one command: a fast-forward pull, then the same preview and confirmation as a
switch.

```sh
mise run update --tier shell
```

The lock file only moves when a commit moves it, so a pull is the whole of an update and two
machines on the same commit have the same versions.

### Undoing a switch

Every switch is a generation, kept beside the earlier ones. The home-manager command is not
installed, so a rollback is the earlier generation's own activation script:

```sh
ls ~/.local/state/nix/profiles/
~/.local/state/nix/profiles/home-manager-<N>-link/activate
```

(`~/.local/state` is `XDG_STATE_HOME` when that is set.)

### Giving the machine back

```sh
/nix/nix-installer uninstall
```

removes Nix, the store and the daemon. The links under `~` then dangle and can be deleted; the
backups the switch made are still beside them with their original contents.

## Day to day

| Command | What it does |
| --- | --- |
| `mise run check --tier shell` | Build one configuration and touch nothing. A broken change is caught here. |
| `mise run switch --tier shell` | Build, preview the change to this home, ask once, activate. |
| `mise run update --tier shell` | Pull the checkout, then switch. |
| `mise run setup --tier shell` | One plan and one question for the switch, pacman, the greeter and the memories, where each applies. |
| `mise run pacman --tier shell` | Preview the derived pacman and AUR lists against what is installed, ask once, install. Linux with pacman only. |
| `mise run tiers` | Print what Shell and Desktop contain on each platform, with each program's source. |

`check`, `switch`, `update`, `setup` and `pacman` take `--tier shell` or `--tier desktop`
and an optional `--platform`; the platform is detected when not given. `tiers` takes nothing
and prints every platform.

**Editing a config** needs no step: the file under `~` is a link to the file in the checkout,
so the program sees the edit at once. Only an applied file waits for the next switch.

**Updating the versions** is a deliberate act: `nix flake update`, a `check` of each
configuration that matters to you, and a commit of `flake.lock`. Every machine then picks the
new versions up on its next `update`.

**Running nix directly.** Every `nix` command here takes `--impure`, because the username and
home are read from the environment. From anywhere other than `~/SMS-Supercharge-My-Shell` (a
worktree, a container, CI) set `SMS_CHECKOUT` to the checkout the live links should point at,
or the build refuses:

```sh
SMS_CHECKOUT=$PWD nix flake check --impure
```

The mise tasks set it to the checkout they run from, so a switch from a worktree links the
home into that worktree, and a switch from the main checkout brings it back.

## Changing what a machine has

Every change is to one program directory, and the checks say whether the tree still agrees
with itself.

### Add a program

1. Create `programs/<name>/` with a `program.nix` naming the tier and, for each platform the
   program exists on, exactly one install source and the package name there. A program with
   nothing to configure (1Password) is the declaration alone.
2. Put its config beside the declaration, shaped like `~`: `programs/<name>/.config/<name>/...`
   lands at `~/.config/<name>/...`. Every file becomes a live link. Directories under `~` are
   always real directories, never links, so the program's own runtime files beside ours are
   untouched.
3. `git add` the directory. The flake sees only tracked files, and an untracked one reads as
   missing.
4. `mise run check --tier <tier>`, then `SMS_CHECKOUT=$PWD nix flake check --impure`, then
   `mise run tiers` to see it in place, then `switch`.

A program whose source is `pacman` or `aur` is declared the same way; the switch links its
config and the derived list gains a line, which `mise run pacman` installs. A program
nixpkgs does not carry gets a `package.nix` in its directory and `install.<platform>.repo =
"<name>"`; ccstatusline is the example.

A file the program never rewrites itself and that should roll back with the packages, a
script the package runs say, is named in `applied = [ ".config/<name>/<file>" ]` in the
declaration; the switch copies it into place instead of linking. Anything a program rewrites
on its own (fish's variables, the Claude settings, Noctalia's state) has to stay live.

### Remove a program

Delete `programs/<name>/` and switch. The preview lists the package as removed and every link
it owned as unlinked; there is no list anywhere else to edit. A `pacman` or `aur` program is
removed from the derived list the same way, and the installed package is yours to remove with
`pacman -Rs`, since the configuration never uninstalls what the distro installed.

Six runtimes (`bun`, `cargo`, `go`, `node`, `rustc`, `uv`) are held by a check that names
them, so that deleting one is a refusal and not a silent change to what a Shell machine has.

### Move a program, or change where it comes from

Change `tier` to move a program between Shell and Desktop. Change `install.<platform>` to
change its source on one platform, or remove the platform's entry to take the program off that
platform altogether. `mise run tiers` shows the result and the flake checks hold it to the
declaration: each program appears in exactly the tiers and platforms it names, Desktop
contains all of Shell, and each derived list equals its declarations.

### Add something that belongs to a platform

What is no program's, the session stack on Linux for one, goes in the platform directory.
`platforms/<platform>/platform.nix` lists distro packages per tier and source, and joins the
derived list. `platforms/<platform>/<tier>.nix` is an ordinary home-manager module for what
home-manager adds to that tier there: fonts, the cursor theme and the session environment for
the Linux Desktop today. A platform whose directory holds only an empty `platform.nix` still
builds; that is how macOS and WSL2 exist.

Adding a tier or a platform is rarer: `nix/vocabulary.nix` names them once, and the pairs that
build are listed in `flake.nix`.

### What the checks refuse

The build refuses rather than installing something nowhere: a tier or platform the vocabulary
does not have, a source that is not one of the known ones, an applied file the program does
not ship, a `repo` package with no `package.nix`, a path two programs both claim, and a
checkout that is not there or holds no `programs/`. `nix flake check` adds the assertions
above, builds every configuration for the machine's system, and checks that every live link
points into the checkout and every applied file into the store.
