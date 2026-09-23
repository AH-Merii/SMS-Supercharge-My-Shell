# SMS Supercharge-My-Shell

The dotfiles and the setup that carry one person's working environment onto any machine they
are handed: a Linux desktop, a Mac, a Windows box through WSL2, or a bare server.

## Language

### Tiers

**Shell**:
The layer every machine has in common: the shell, the editor, the multiplexer, git and the
command-line tools, with their configs. The same on Linux, macOS and WSL2; a machine that has
only this is fully usable from a terminal. "The shell" alone means this layer; the program is
always called fish.
_Avoid_: terminal, headless, base, minimal, core

**Desktop**:
The graphical session on top of Shell. What it contains depends on the platform.
_Avoid_: GUI profile, full

### Platforms

**Platform**:
What a machine runs: Linux, macOS or WSL2. The tier says what a machine gets; the platform
says how it is installed and which programs exist there at all. Every machine is one tier on
one platform.
_Avoid_: OS, target, host type

### Machine situations

**Fresh machine**:
A machine with nothing of ours on it yet: no software installed for us, no configs in place.

**Existing machine**:
A machine that already has some of our programs installed by other means, or configs of its
own in the paths we manage. The setup takes ownership of both and backs up what it replaces.
_Avoid_: dirty machine, adopted machine

**Set-up machine**:
A machine the setup has already run on, now behind the repo and wanting to catch up.
_Avoid_: existing machine (that means the situation above), stale machine

### Software

**Tool**:
A program installed for the machine as a whole, in one version, from the repo's single lock
file. Everything a machine has outside a project is a tool, language runtimes included.
_Avoid_: global package, dependency

**Project pin**:
A version of a language runtime that one project requires, honoured only inside that
project and never installed for the machine as a whole.
_Avoid_: dev dependency, local version, toolchain

**Install source**:
Where a program comes from on one platform: nixpkgs, the repo, pacman or the AUR. A program's
declaration names exactly one per platform it exists on. A nixpkgs program and a repo one --
built from a `package.nix` in the program's own directory, for what nixpkgs does not carry --
are installed by the configuration itself; the rest are handed to the distro's own install step.
_Avoid_: package manager, backend, provider, install method

**Distro list**:
The packages of one install source that a configuration expects the distro to install:
the union of the programs of its tiers that name that source and the platform directory's
own list. Computed from the declarations, never written down as a list of its own.
_Avoid_: pkglist, package list, manifest

### Repo units

**Program**:
The unit the repo is organised by: one directory per program holding its config tree shaped
like `~`, plus a declaration of its tier, the platforms it exists on and how it is installed.
A program may have no config tree (1Password) or no install of its own (niri, owned by pacman).
_Avoid_: package (that is the installed artifact), stow package, module

**Platform directory**:
The place for what belongs to a platform rather than to any one program: session wiring on
Linux, machine-level settings on macOS, what differs under WSL2.

### Files

**Live file**:
A config file that `~` reaches through a link into the checkout, so an edit is seen by the
program at once with no build step. The default for every file a program ships.
_Avoid_: symlinked file, out-of-store file

**Checkout**:
Where the repo is cloned on a machine, as a path every live file links into. One string the
configuration is built with, defaulting to the clone under the home directory and overridden
by `SMS_CHECKOUT` to point a build at another one, a worktree under test say. The build
refuses a checkout that is not there or holds no `programs/`.
_Avoid_: repo root, source tree, dotfiles directory

**Applied file**:
A config file copied into place by a switch and changed only by the next switch, so that it
rolls back with the packages. The exception, named per file by the program that ships it.
_Avoid_: managed file, store file, generated file
