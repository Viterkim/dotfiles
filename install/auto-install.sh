#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

remove_old_link() {
  local path=$1 old_target=$2

  if [[ -L $path && $(readlink -- "$path") == "$old_target" ]]; then
    unlink -- "$path"
  fi
}

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/bash"
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/lazygit"
mkdir -p "$HOME/.config/paru"
mkdir -p "$HOME/.config/yazi"

ln -sf "$DOTFILES/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES/.config/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
ln -sf "$DOTFILES/.config/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
ln -sf "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml"
ln -sf "$DOTFILES/.config/yazi/keymap.toml" "$HOME/.config/yazi/keymap.toml"
ln -sf "$DOTFILES/.config/paru/paru.conf" "$HOME/.config/paru/paru.conf"

remove_old_link "$HOME/.config/fish/config.fish" "$DOTFILES/.config/fish/config.fish"
remove_old_link "$HOME/.config/nushell/config.nu" "$DOTFILES/.config/nushell/config.nu"
remove_old_link "$HOME/.wezterm.lua" "$DOTFILES/.wezterm.lua"

sudo usermod -aG docker "$USER"
if [[ $(getent passwd "$USER" | cut -d: -f7) != /usr/bin/bash ]]; then
  sudo chsh -s /usr/bin/bash "$USER"
fi

"$DOTFILES/install/manual-install.sh"
