#!/usr/bin/env bash
set -euo pipefail

is_ssh() {
  [ -n "${SSH_TTY:-}${SSH_CLIENT:-}${SSH_CONNECTION:-}" ]
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

main() {
  if is_ssh; then
    copy_osc52
    exit 0
  fi

  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy
    exit 0
  fi

  if command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
    exit 0
  fi

  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy
    exit 0
  fi

  echo "No clipboard backend found" >&2
  exit 1
}

main "$@"
