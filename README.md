# SMS Supercharge-My-Shell

## About

This directory contains all the dotfiles for a supercharged development environment. It includes an easy way to make sure that all the necessary programs are installed using the `setup.sh` script.
**NOTE**: This setup only works on Arch Linux as it makes heavy use of the AUR.

_Table of Contents_

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

- [`cat:bat`](https://github.com/sharkdp/bat) - _A `cat` clone with syntax highlighting and Git integration._
- [`grep:ripgrep`](https://github.com/BurntSushi/ripgrep) - _An extremely fast alternative to `grep` that respects your gitignore_
- [`ls:exa`](https://github.com/ogham/exa) - _A modern replacement for `ls`_
- [`diff:delta`](https://github.com/dandavison/delta) - _A viewer for `git` and `diff` output_

### Terminal Setup

The setup adds the following tools to terminal gui tools:

- [`lazygit`](https://github.com/jesseduffield/lazygit) - _A simple terminal UI for git commands, written in Go with the gocui library._
- [`lf`](https://github.com/gokcehan/lf) - _A terminal file manager_
- [`fzf`](https://github.com/junegunn/fzf) - _A general purpose command-line fuzzy finder._
- [`powerlevel10k`](https://github.com/romkatv/powerlevel10k) - _A minimal, blazing-fast, and highly customizable prompt for any shell_
- [`neovim`](https://neovim.io/) - _Vim-fork focused on extensibility and usability_ ---> An alternative to Vim

### Zsh

The setup installs `zsh` and sets it as the default shell. The following `zsh` extensions are also installed using [zap](https://github.com/zap-zsh/zap):

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-autopair](https://github.com/hlissner/zsh-autopair)
- [zsh-you-should-use](https://github.com/MichaelAquilina/zsh-you-should-use)
- [zsh-shift-select](https://github.com/jirutka/zsh-shift-select)
- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-completions](https://github.com/zsh-users/zsh-completions)
- [fzf-tab](https://github.com/Aloxaf/fzf-tab)

### Navigation

This setup also includes all the shortcuts for selecting text that you would use on a normal text editor such as:

- `ctrl + ->` move one word right
- `ctrl + <-` move one word left
- `ctrl + shift + ->` select one word right
- `ctrl + shift + <-` select one word left
- `home` go to start of line
- `end` go to end of line
- `shift + home` select to start of line
- `shift + end` select to end of line
- `ctrl + c` during selection copy
- `ctrl + x` during selection cut
- `ctrl + v` paste

## Install

### Prerequisites

- [Arch Linux](https://archlinux.org/) or any [Arch-based distro](https://wiki.archlinux.org/title/Arch-based_distributions)
- [NerdFonts](https://www.nerdfonts.com/font-downloads) compatible font

````
### Setup Script
To automatically setup the development environment simply navigate to the root directory of the repo, and run:
```bash
./setup.sh
````

### Dotfiles

If you would simply like to copy the dotfiles, then while you are in `setup.sh` simply skip the other steps when prompted and only run the step related to the configs.

**_OR_**
Run `stow` to symlink everything or just select what you want

```bash
stow */ -t ~ # creates a symlink for all config files
```

```bash
stow zsh # creates symlink for only zsh configs
```

### Systemd Services

In addition to managing your dotfiles, this setup allows you to manage custom `systemd` services in a structured and version-controlled manner. These services are stored in the `systemd` directory, and you can use `stow` to symlink them to the appropriate location under `/etc/systemd/system`.

#### What It Does:

This setup makes it easy to manage custom `systemd` services (such as `nvidia-pm.service` for enabling Nvidia persistent mode) by organizing them into directories and using `stow` to symlink them to their correct system locations. This approach helps keep your services version-controlled and modular, just like your dotfiles.

#### How It Works:

1. **Store your custom services** under `systemd/etc/systemd/system/custom-services/`.
   - Example structure: `systemd/etc/systemd/system/custom-services/nvidia/nvidia-pm.service`
2. **Use `stow` to symlink these services** to the system-wide `systemd` directory (`/etc/systemd/system/`) so that they can be managed by `systemd`.

#### Using `stow` with `systemd` Services:

Unlike stowing dotfiles, stowing `systemd` services requires `sudo` privileges because you need to create symlinks in `/etc/systemd/system`. Additionally, you need to specify the target directory as `/` so that `stow` places the services correctly under `/etc/systemd/system/`.

##### Example:

To stow all your `systemd` services, run the following command from the root of your repository:

```bash
sudo stow -t / systemd
```

#### Enabling and Starting Services:

After symlinking the service files, you'll need to reload `systemd` to recognize them:

```bash
sudo systemctl daemon-reload
```

The **cool part** about this setup is that you can control which services are active. Even though all services are symlinked, you still need to **enable the specific services** you want to use. So, you can easily stow all services but only enable those you need.

To enable and start a service:

```bash
sudo systemctl enable nvidia-pm.service
sudo systemctl start nvidia-pm.service
```

This way, you can manage multiple services and only activate the ones you require at any given time.
