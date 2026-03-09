#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

sudo pacman -S --needed base-devel git

if ! command -v paru >/dev/null 2>&1; then
  cd /tmp
  rm -rf paru
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
fi

xargs -a "$DOTFILES/arch-packages.txt" paru -S --needed --
