#!/usr/bin/env bash
set -euo pipefail

link="${1:-}"
case "$link" in
  http://*|https://*) ;;
  *)
    printf 'Refusing to open invalid URL: %s\n' "$link" >&2
    exit 1
    ;;
esac

is_ssh() {
  [ -n "${SSH_TTY:-}${SSH_CLIENT:-}${SSH_CONNECTION:-}" ]
}

is_wsl() {
  [ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ] || [[ "$(uname -r)" == *[Mm]icrosoft* ]]
}

if is_ssh; then
  printf '%s' "$link" | +clipcopy.sh
  printf 'Remote session: copied link to the client clipboard: %s\n' "$link"
elif is_wsl && command -v wslview >/dev/null 2>&1; then
  wslview "$link"
elif is_wsl && command -v powershell.exe >/dev/null 2>&1; then
  # PowerShell, not Bash, expands $env here.
  # shellcheck disable=SC2016
  OPEN_LINK_URL="$link" powershell.exe -NoProfile -NonInteractive -Command 'Start-Process -FilePath $env:OPEN_LINK_URL'
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$link" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
  open "$link"
else
  printf '%s' "$link" | +clipcopy.sh
  printf 'No browser opener found: copied link to the clipboard\n'
fi
