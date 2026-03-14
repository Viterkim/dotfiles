#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/fish"
mkdir -p "$HOME/.config/paru"

ln -sf "$DOTFILES/.config/fish/config.fish" "$HOME/.config/fish/config.fish"
ln -sf "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml"
ln -sf "$DOTFILES/.wezterm.lua" "$HOME/.wezterm.lua"
ln -sf "$DOTFILES/.config/paru/paru.conf" "$HOME/.config/paru/paru.conf"

sudo usermod -aG docker $USER

"$DOTFILES/install/manual-install.sh"
