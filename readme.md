# dotfiles - viter / viterkim

## Install
- auto-install.sh automatically runs ./manual-install.sh for printed manual instructions
```bash
git clone git@github.com:Viterkim/dotfiles.git ~/dotfiles
~/dotfiles/install/auto-install-packages.sh
~/dotfiles/install/auto-install.sh
```

# Breakdown

## Initial Arch System Packages (install/auto-install-packages.sh)
- Installs paru
- Installs packages from arch-packages.txt

## Linked (install/auto-install.sh)
- .config/fish/config.fish
- .config/starship.toml
- .config/paru/paru.conf
- .wezterm.lua

## Manual (install/manual-install.sh)
- .gitconfig
- gnome-settings.dconf 

## Added to PATH
- own_bin

## Nvim Config (Not in this repo)
- Link to Nvim / Neovim repo [Github Link](https://github.com/Viterkim/astro5)
- Should manually be cloned to: .config/nvim
