#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

mkdir -p "$HOME/.config/fish"
mkdir -p "$HOME/.config/paru"

ln -sf "$DOTFILES/.config/fish/config.fish" "$HOME/.config/fish/config.fish"
ln -sf "$DOTFILES/.wezterm.lua" "$HOME/.wezterm.lua"
ln -sf "$DOTFILES/.config/paru/paru.conf" "$HOME/.config/paru/paru.conf"

"$DOTFILES/install/manual-install.sh"
