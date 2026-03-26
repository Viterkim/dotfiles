#!/usr/bin/env bash
set -euo pipefail

usage() {
  local exit_code="${1:-0}"

  echo "usage: $(basename "$0") <mode>"
  echo

  if command -v powerprofilesctl >/dev/null 2>&1; then
    echo "current: $(powerprofilesctl get)"
  else
    echo "current: (powerprofilesctl not available)"
  fi

  echo
  echo "modes:"
  echo
  echo "  --aggressive, --performance, --high  set performance mode"
  echo "  --power-saver, --saver, --save,"
  echo
  echo "  --normal, --balanced, --mid          set balanced mode"
  echo
  echo "  --power-save, --low                  set power-saver mode"
  echo
  echo "other:"
  echo "  --current                           show current mode"
  echo "  --list                              list available modes"
  echo "  --help, -h                          show this help"

  exit "$exit_code"
}

die() {
  echo "$*" >&2
  exit 1
}

require_cmd() {
  command -v powerprofilesctl >/dev/null 2>&1 \
    || die "powerprofilesctl not found (install power-profiles-daemon)"
}

cmd_set_mode() {
  local mode="$1"
  local before
  local after

  require_cmd
  before="$(powerprofilesctl get)"

  echo "Was: $before"
  echo

  if [ "$before" = "$mode" ]; then
    echo "Setting to: $mode (again)"
  else
    echo "Setting to: $mode"
  fi

  powerprofilesctl set "$mode"
  after="$(powerprofilesctl get)"
  echo
  echo "Now: $after"
}

cmd_current() {
  require_cmd
  powerprofilesctl get
}

cmd_list() {
  require_cmd
  powerprofilesctl list
}

main() {
  case "${1-}" in
    ""|--help|-h)
      usage
      ;;

    # balanced
    --normal|--balanced|--mid)
      shift
      [ "$#" -eq 0 ] || usage 1
      cmd_set_mode balanced
      ;;

    # performance
    --aggressive|--performance|--high)
      shift
      [ "$#" -eq 0 ] || usage 1
      cmd_set_mode performance
      ;;

    # power saver
    --power-saver|--saver|--save|--power-save|--low)
      shift
      [ "$#" -eq 0 ] || usage 1
      cmd_set_mode power-saver
      ;;

    --current)
      shift
      [ "$#" -eq 0 ] || usage 1
      cmd_current
      ;;

    --list)
      shift
      [ "$#" -eq 0 ] || usage 1
      cmd_list
      ;;

    *)
      echo "Unknown option: $1" >&2
      echo >&2
      usage 1
      ;;
  esac
}

main "$@"
