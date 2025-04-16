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

- [NerdFonts](https://www.nerdfonts.com/font-downloads) compatible font

### Setup Script
To install the dotfiles you can run the following command in your terminal:
```bash
bash <(curl -s https://raw.githubusercontent.com/AH-Merii/SMS-Supercharge-My-Shell/main/scripts/install.sh)
```

### Dotfiles
Run `stow` to symlink everything or just select what you want

```bash
stow */ -t ~ # creates a symlink for all config files
```

```bash
stow zsh # creates symlink for only zsh configs
```

### Systemd Services

In addition to managing your dotfiles, this setup allows you to manage custom `systemd` services. These services are stored in the `services/systemd` directory, and to activate them, you can simply copy them to `/etc/systemd/system`. A better approach is to create a dedicated directory like `/etc/systemd/system/custom-services` to keep track of which services are custom.

#### How It Works:

1. **Store your custom services** under `services/systemd/`.
   - Example structure: `services/systemd/nvidia-pm.service`
2. **Copy the services** to `/etc/systemd/system/`:
   ```bash
   sudo cp services/systemd/* /etc/systemd/system/custom-services/
   ```

#### Enabling and Starting Services:

After copying the service files, you'll need to reload `systemd` to recognize them:

```bash
sudo systemctl daemon-reload
```

You can now enable and start the service:

```bash
sudo systemctl enable nvidia-pm.service
sudo systemctl start nvidia-pm.service
```

This way, you can easily keep track of all your custom services and only activate the ones you need.
