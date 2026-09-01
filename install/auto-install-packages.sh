#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
ARCH_PACKAGES="$DOTFILES/arch-packages.txt"
AUR_PACKAGES="$DOTFILES/aur-packages.txt"

sudo pacman -S --needed base-devel git

xargs -r -a "$ARCH_PACKAGES" sudo pacman -S --needed --

if [ -s "$AUR_PACKAGES" ]; then
  printf 'Install reviewed AUR packages from %s? [y/N] ' "$AUR_PACKAGES"
  read -r install_aur

  case "$install_aur" in
    y|Y|yes|YES)
      if ! command -v paru >/dev/null 2>&1; then
        paru_build_dir="$(mktemp -d)"
        git clone https://aur.archlinux.org/paru.git "$paru_build_dir/paru"
        cd "$paru_build_dir/paru"
        makepkg -si
      fi

      xargs -r -a "$AUR_PACKAGES" paru -S --needed --
      ;;
    *)
      echo "Skipping AUR packages."
      ;;
  esac
fi
