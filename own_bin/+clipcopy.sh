#!/usr/bin/env bash
set -euo pipefail

usage() {
  local exit_code="${1:-0}"

  cat >&2 <<'EOF'
usage: clipcopy.sh [--backend | --file <path>]
  no args        copy stdin to clipboard
  --backend      print selected clipboard backend
  --file <path>  copy file contents to clipboard
EOF

  exit "$exit_code"
}

is_ssh() {
  [ -n "${SSH_TTY:-}${SSH_CLIENT:-}${SSH_CONNECTION:-}" ]
}

detect_backend() {
  if is_ssh; then
    printf '%s\n' "osc52"
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s\n' "wl-copy"
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s\n' "xclip"
  elif command -v pbcopy >/dev/null 2>&1; then
    printf '%s\n' "pbcopy"
  else
    printf '%s\n' "unknown"
  fi
}

copy_osc52() {
  local b64
  b64="$(base64 | tr -d '\r\n')"

  if [ -n "${TMUX:-}" ]; then
    # tmux passthrough
    printf '\033Ptmux;\033\033]52;c;%s\a\033\\' "$b64"
  else
    printf '\033]52;c;%s\a' "$b64"
  fi
}

print_backend() {
  local backend
  backend="$(detect_backend)"
  [ "$backend" != "unknown" ] || {
    echo "No clipboard backend found" >&2
    return 1
  }
  printf '%s\n' "$backend"
}

copy_stdin() {
  case "$(detect_backend)" in
    osc52)
      copy_osc52
      ;;
    wl-copy)
      wl-copy
      ;;
    xclip)
      xclip -selection clipboard
      ;;
    pbcopy)
      pbcopy
      ;;
    *)
      echo "No clipboard backend found" >&2
      return 1
      ;;
  esac
}

main() {
  case "${1-}" in
    "")
      [ "$#" -eq 0 ] || usage 1
      copy_stdin
      ;;
    --backend)
      [ "$#" -eq 1 ] || usage 1
      print_backend
      ;;
    --file)
      [ "$#" -eq 2 ] || usage 1
      [ -f "$2" ] || { echo "File not found: $2" >&2; exit 1; }
      cat -- "$2" | copy_stdin
      ;;
    -h|--help)
      usage 0
      ;;
    *)
      usage 1
      ;;
  esac
}

main "$@"
