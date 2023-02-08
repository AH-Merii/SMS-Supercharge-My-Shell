# Dotfiles
## About
This directory contains all the dotfiles for a supercharged development environment. It includes an easy way to make sure that all the necessary programs are installed using the `setup.sh` script.

*Table of Contents*
- [About](#about)
    - [Modern Unix Tools](#modern-unix-tools)
    - [Terminal Setup](#terminal-setup)
    - [Zsh](#zsh)
- [Install](#install)
    - [Prerequisites](#prerequisites)
    - [Setup Script](#setup-script)
    - [Dotfiles](#dotfiles)
    - [Programs](#programs)

## Modern Unix Tools
The setup adds the following modern unix tools and creates aliases for their GNU counterparts:
* [`cat:bat`](https://github.com/sharkdp/bat) - *A cat clone with syntax highlighting and Git integration.*
* [`grep:ripgrep`](https://github.com/BurntSushi/ripgrep) - *An extremely fast alternative to grep that respects your gitignore*
* [`ls:exa`](https://github.com/ogham/exa) - *A modern replacement for `ls`*
* [`find:fd`](https://github.com/sharkdp/fd) - *A simple, fast user friendly alternative to `find`*
* [`diff:delta`](https://github.com/dandavison/delta) - *A viewer for `git` and `diff` output*
* [`curl:xh`](https://github.com/ducaale/xh) - *A friendly and fast tool for sending HTTP requests. It reimplements as much as possible of `HTTPie`'s excellent design, with a focus on improved performance.*
* [`du:duf`](https://github.com/muesli/duf) - *A better `df` alternative*
* [`dig:dogdns`](https://github.com/ogham/dog) - *A user-friendly command-line DNS client. `dig` on steroids*
* [`ps:procs`](https://github.com/dalance/procs) - *A modern replacement for `ps` written in Rust.*
* [`ping:gping`](https://github.com/orf/gping) - *`ping` but with a graph*
* [`top:bottom`](https://github.com/ClementTsang/bottom) - *Yet another cross-platform graphical process/system monitor.*
* [`du:du-dust`](https://github.com/bootandy/dust) - *A more intuitive version of du written in rust.*

### Terminal Setup
The setup adds the following tools to terminal gui tools:
* [`zellij`](https://github.com/zellij-org/zellij) - *A terminal workspace with batteries included*
* [`lazygit`](https://github.com/jesseduffield/lazygit) - *A simple terminal UI for git commands, written in Go with the gocui library.*
* [`lf`](https://github.com/gokcehan/lf) - *A terminal file manager*
* [`fzf`](https://github.com/junegunn/fzf) - *A general purpose command-line fuzzy finder.*
* [`starship`](https://github.com/starship/starship) - *A minimal, blazing-fast, and infinitely customizable prompt for any shell*
* [`helix`](https://helix-editor.com/) - *Post Modern Modal Text Editor* ---> An alternative to Vim
 
### Zsh
The setup installs `zsh` and sets it as the default shell. The following `zsh` extensions are also installed using [zap](https://github.com/zap-zsh/zap):
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
* [zsh-autopair](https://github.com/hlissner/zsh-autopair)
* [supercharge](https://github.com/zap-zsh/supercharge)
* [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
* [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode)
* [exa](https://github.com/zap-zsh/exa)
* [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
* [fzf-tab](https://github.com/Aloxaf/fzf-tab)

## Install
### Prerequisites
* [ssh connection to github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) ps: [info on using `~/.ssh/config`](https://www.freecodecamp.org/news/how-to-manage-multiple-ssh-keys/) 
* [NerdFonts](https://www.nerdfonts.com/font-downloads) compatible font
* If you are on wsl2 -> make sure you [enable systemd](https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/)


You will need `git` and GNU `stow`

Clone into your `$HOME` directory or `~`

Modify the `.gitconfig` file found in the gitconfig directory, and add your name and email.

```bash
git clone git@github.com:AH-Merii/dotfiles.git ~
```

### Setup Script
To automatically setup the development environment simply navigate to the root directory of the repo, and run: 
```bash
./setup.sh
```

### Dotfiles
You can copy specific configurations without going through the entire setup, using the `stow` command. 

Run `stow` to symlink everything or just select what you want

```bash
stow */ -t ~ # creates a symlink for all config files
```

```bash
stow zsh # creates symlink for only zsh configs
```

### Programs
The setup installs [nix package manager](https://nixos.org/) and uses it to install most of the programs used in the development environment. 

An updated list of all the programs can be found in the `programs` directory
