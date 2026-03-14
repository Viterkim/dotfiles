#!/usr/bin/env bash
set -euo pipefail

usage() {
  local exit_code="${1:-0}"

  echo "usage: $(basename "$0") <command> [args]"
  echo
  echo "commands:"
  echo "  --list-aur                  list foreign packages"
  echo "  --who <name>                show which package owns a command or path"
  echo "  --latest-packages [count]   show most recently installed packages (default: 20)"
  echo "  --what-bin <package>        show every executable file shipped by a package"
  echo "  --help, -h                  show this help"

  exit "$exit_code"
}

die() {
  echo "$*" >&2
  exit 1
}

cmd_list_aur() {
  pacman -Qmq
}

cmd_who() {
  local name="${1:-}"
  local target=""

  [ -n "$name" ] || die "Missing name for --who"

  if [[ "$name" == */* ]]; then
    target="$name"
  else
    target="$(command -v "$name" || true)"
  fi

  [ -n "$target" ] || die "Command not found: $name"

  pacman -Qo -- "$target"
}

cmd_latest_packages() {
  local count="${1:-20}"
  local log_file="/var/log/pacman.log"

  [[ "$count" =~ ^[0-9]+$ ]] || die "Count must be a non-negative integer"
  [ -r "$log_file" ] || die "Cannot read $log_file"

  tac "$log_file" \
    | awk '
        /\[ALPM\] installed / {
          line = $0

          sub(/^.*\[ALPM\] installed /, "", line)
          pkg = line
          sub(/ \(.*/, "", pkg)

          print pkg
        }
      ' \
    | head -n "$count" \
    | tac
}

cmd_what_bin() {
  local pkg="${1:-}"
  local found=0
  local path=""

  [ -n "$pkg" ] || die "Missing package name for --what-bin"
  pacman -Q -- "$pkg" >/dev/null 2>&1 || die "Package not installed: $pkg"

  while IFS= read -r path; do
    if [ -f "$path" ] && [ -x "$path" ]; then
      printf '%s\n' "$path"
      found=1
    fi
  done < <(pacman -Qlq -- "$pkg")

  [ "$found" -eq 1 ] || die "No executable files found in package: $pkg"
}

main() {
  case "${1-}" in
    ""|--help|-h)
      usage
      ;;

    --list-aur)
      shift
      [ "$#" -eq 0 ] || usage 1
      cmd_list_aur
      ;;

    --who)
      shift
      [ "$#" -eq 1 ] || usage 1
      cmd_who "$1"
      ;;

    --latest-packages)
      shift
      case "$#" in
        0)
          cmd_latest_packages 20
          ;;
        1)
          cmd_latest_packages "$1"
          ;;
        *)
          usage 1
          ;;
      esac
      ;;

    --what-bin)
      shift
      [ "$#" -eq 1 ] || usage 1
      cmd_what_bin "$1"
      ;;

    *)
      echo "Unknown command: $1" >&2
      echo >&2
      usage 1
      ;;
  esac
}

main "$@"

