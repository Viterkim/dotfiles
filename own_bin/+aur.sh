#!/usr/bin/env bash
set -euo pipefail

usage() {
  local exit_code="${1:-0}"

  echo "usage: $(basename "$0") <command> [args]"
  echo
  echo "commands:"
  echo "  --list-aur         list foreign packages"
  echo "  --who <name>       show which package owns a command or path"
  echo "  --help, -h         show this help"

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

    *)
      echo "Unknown command: $1" >&2
      echo >&2
      usage 1
      ;;
  esac
}

main "$@"
