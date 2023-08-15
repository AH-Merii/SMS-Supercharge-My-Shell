# SMS Supercharge-My-Shell
![image](https://github.com/AH-Merii/SMS-Supercharge-My-Shell/assets/43741215/09bfeb3b-3387-47e3-9ef9-34dae4ba4b41)

## About
This directory contains all the dotfiles for a supercharged development environment. It includes an easy way to make sure that all the necessary programs are installed using the `setup.sh` script.
**NOTE**: This setup only works on Arch Linux as it makes heavy use of the AUR.

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
* [`cat:bat`](https://github.com/sharkdp/bat) - *A `cat` clone with syntax highlighting and Git integration.*
* [`grep:ripgrep`](https://github.com/BurntSushi/ripgrep) - *An extremely fast alternative to `grep` that respects your gitignore*
* [`ls:exa`](https://github.com/ogham/exa) - *A modern replacement for `ls`*
* [`diff:delta`](https://github.com/dandavison/delta) - *A viewer for `git` and `diff` output*

### Terminal Setup
The setup adds the following tools to terminal gui tools:
* [`lazygit`](https://github.com/jesseduffield/lazygit) - *A simple terminal UI for git commands, written in Go with the gocui library.*
* [`lf`](https://github.com/gokcehan/lf) - *A terminal file manager*
* [`fzf`](https://github.com/junegunn/fzf) - *A general purpose command-line fuzzy finder.*
* [`powerlevel10k`](https://github.com/romkatv/powerlevel10k) - *A minimal, blazing-fast, and highly customizable prompt for any shell*
* [`helix`](https://helix-editor.com/) - *Post Modern Modal Text Editor* ---> An alternative to Vim
 
### Zsh
The setup installs `zsh` and sets it as the default shell. The following `zsh` extensions are also installed using [zap](https://github.com/zap-zsh/zap):
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
* [zsh-autopair](https://github.com/hlissner/zsh-autopair)
* [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
* [zsh-shift-select](https://github.com/jirutka/zsh-shift-select)
* [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
* [zsh-completions](https://github.com/zsh-users/zsh-completions)
* [fzf-tab](https://github.com/Aloxaf/fzf-tab)

### Navigation
This setup also includes all the shortcuts for selecting text that you would use on a normal text editor such as:
* `ctrl + ->`         move one word right
* `ctrl + <-`         move one word left
* `ctrl + shift + ->` select one word right
* `ctrl + shift + <-` select one word left
* `home`              go to start of line
* `end`               go to end of line
* `shift + home`      select to start of line
* `shift + end`       select to end of line
* `ctrl + c`          during selection copy
* `ctrl + x`          during selection cut
* `ctrl + v`          paste

## Install
### Prerequisites
* [Arch Linux](https://archlinux.org/) or any [Arch-based distro](https://wiki.archlinux.org/title/Arch-based_distributions)
* [NerdFonts](https://www.nerdfonts.com/font-downloads) compatible font

```
### Setup Script
To automatically setup the development environment simply navigate to the root directory of the repo, and run: 
```bash
./setup.sh
```

### Dotfiles
If you would simply like to copy the dotfiles, then while you are in `setup.sh` simply skip the other steps when prompted and only run the step related to the configs.

***OR***
Run `stow` to symlink everything or just select what you want

```bash
stow */ -t ~ # creates a symlink for all config files
```

```bash
stow zsh # creates symlink for only zsh configs
```
