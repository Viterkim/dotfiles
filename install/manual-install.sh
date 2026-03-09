#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

echo "manual steps: (remember to run this)"
echo
echo "set fish as default shell:"
echo "chsh -s /usr/bin/fish"
echo
echo "restore gnome settings:"
echo "dconf load / < \"$DOTFILES/gnome-settings.dconf\""
echo
echo "copy git config + manually set mail/email:"
echo "cp -f \"$DOTFILES/.gitconfig\" \"$HOME/.gitconfig\""
echo "git config --global user.email \"REPLACE@ME.COM\""
echo
echo "clone nvim repo (https://github.com/Viterkim/astro5):"
echo "mkdir -p \"$HOME/.config\" && git clone git@github.com:Viterkim/astro5.git \"$HOME/.config/nvim\""
