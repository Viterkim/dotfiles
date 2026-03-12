#!/usr/bin/env bash
set -euo pipefail

swap_dir="/home/viter/.xdg/nvim/swap"
timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
backup_root="${swap_dir%/}/_old"
backup_dir="${backup_root}/${timestamp}"

usage() {
  echo "usage: $(basename "$0") [--fix]"
  echo
  echo "  --fix    show swap files, ask for confirmation, then move them away"
}

show_swap_dir() {
  echo "Swap dir: $swap_dir"
  echo
  ls -lha "$swap_dir"
  echo
}

print_plan() {
  echo "Would move everything from:"
  echo "  $swap_dir"
  echo "to:"
  echo "  $backup_dir"
  echo
  echo "Run:"
  echo "  $(basename "$0") --fix"
}

move_swap_files() {
  mkdir -p "$backup_dir"

  shopt -s nullglob dotglob
  files=()
  for path in "$swap_dir"/*; do
    [[ "$(basename "$path")" == "_old" ]] && continue
    files+=("$path")
  done
  shopt -u dotglob

  if ((${#files[@]} == 0)); then
    echo "Nothing to move."
    rmdir "$backup_dir" 2>/dev/null || true
    return 0
  fi

  mv -- "${files[@]}" "$backup_dir"/

  echo
  echo "Moved ${#files[@]} item(s) to:"
  echo "  $backup_dir"
}

main() {
  case "${1-}" in
    --help|-h)
      usage
      ;;
    --fix)
      show_swap_dir
      read -r -p "Move everything into $backup_dir ? [y/N] " reply
      case "$reply" in
        y|Y)
          move_swap_files
          ;;
        *)
          echo "Aborted."
          ;;
      esac
      ;;
    "")
      show_swap_dir
      print_plan
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
