# dotfiles - viter / viterkim

## Install

- auto-install.sh automatically runs ./manual-install.sh for printed manual instructions

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
- .wezterm.lua
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

## Added to PATH

- dotfiles/own_bin/wrappers
- dotfiles/own_bin
- own_bin_cc and own_bin_cc/wrappers
- hva/scripts
- Cargo, local, and .NET user binaries

## Nvim Config (Not in this repo)

- Link to Nvim / Neovim repo [Github Link](https://github.com/Viterkim/astro6)
- Should manually be cloned to: .config/nvim
