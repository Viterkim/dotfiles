# dotfiles - viter / viterkim

## Install

The package script installs the saved official package list and offers the reviewed
AUR list. The other one links the configs, makes Bash the login shell, removes
links left by the old Fish, Nushell and WezTerm setup, then prints the remaining
manual steps.

```bash
git clone git@github.com:Viterkim/dotfiles.git ~/dotfiles
~/dotfiles/install/auto-install-packages.sh
~/dotfiles/install/auto-install.sh
```

# Breakdown

## Personal Packages (install/auto-install-packages.sh)

- Installs official repository packages from arch-packages.txt with pacman
- Optionally installs reviewed AUR packages from aur-packages.txt with paru

## Linked (install/auto-install.sh)

- .bashrc
- .bash_profile
- .config/ghostty/config.ghostty
- .config/lazygit/config.yml
- .config/starship.toml
- .config/paru/paru.conf
- .config/yazi/keymap.toml

## Bash secrets

Shell secrets live outside Git in `~/.config/bash/secrets.bash`. Use Bash export
syntax and keep the file private:

```bash
mkdir -p ~/.config/bash
chmod 700 ~/.config/bash
$EDITOR ~/.config/bash/secrets.bash
chmod 600 ~/.config/bash/secrets.bash
```

Convert old Fish entries such as `set -gx NAME "value"` to:

```bash
export NAME='value'
```

## Manual (install/manual-install.sh)

- .gitconfig
- gnome-settings.dconf
- fake_rootfs system files
- Nvim config from [astro6](https://github.com/Viterkim/astro6)

## Added to PATH

- dotfiles/own_bin/wrappers
- dotfiles/own_bin
- own_bin_cc and own_bin_cc/wrappers
- hva/scripts
- Cargo, local, and .NET user binaries

## Nvim Config (Not in this repo)

- Link to Nvim / Neovim repo [Github Link](https://github.com/Viterkim/astro6)
- Should manually be cloned to: .config/nvim
