#!/usr/bin/env bash
set -euo pipefail

# TODO: this did not seem to really help / random errors

TARGET_POWER_LIMIT="${NVIDIA_CHANGED_POWER_LIMIT:-130}"

usage() {
  local exit_code="${1:-0}"

  echo "usage: $(basename "$0") <mode>"
  echo
  echo "modes:"
  echo
  echo "  --normal, --default, --mid     reset GPU clocks and restore default power limit"
  echo "  --changed                      enable persistence mode and set power limit to ${TARGET_POWER_LIMIT} W"
  echo
  echo "other:"
  echo "  --current                      show current GPU power/clock state"
  echo "  --list                         list available modes"
  echo "  --help, -h                     show this help"
  echo
  echo "env:"
  echo "  NVIDIA_CHANGED_POWER_LIMIT     override changed-mode power limit (default: ${TARGET_POWER_LIMIT})"

  exit "$exit_code"
}

die() {
  echo "$*" >&2
  exit 1
}

require_cmd() {
  command -v nvidia-smi >/dev/null 2>&1 \
    || die "nvidia-smi not found"
}

run_nvidia_smi() {
  require_cmd

  if [ "$(id -u)" -eq 0 ]; then
    nvidia-smi "$@"
  else
    sudo nvidia-smi "$@"
  fi
}

get_power_value() {
  local label="$1"

  nvidia-smi -q -d POWER | awk -F: -v label="$label" '
    $1 ~ label {
      value = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      sub(/ W.*/, "", value)
      print value
      exit
    }
  '
}

round_watts() {
  local value="$1"
  awk -v x="$value" 'BEGIN { printf "%.0f\n", x }'
}

get_current_limit() {
  local raw
  raw="$(get_power_value "Current Power Limit")"
  [ -n "$raw" ] || die "Could not read current power limit"
  round_watts "$raw"
}

get_default_limit() {
  local raw
  raw="$(get_power_value "Default Power Limit")"
  [ -n "$raw" ] || die "Could not read default power limit"
  round_watts "$raw"
}

get_max_limit() {
  local raw
  raw="$(get_power_value "Max Power Limit")"
  [ -n "$raw" ] || die "Could not read max power limit"
  round_watts "$raw"
}

detect_mode() {
  local current default

  current="$(get_current_limit)"
  default="$(get_default_limit)"

  if [ "$current" = "$TARGET_POWER_LIMIT" ] && [ "$current" != "$default" ]; then
    echo "changed"
  elif [ "$current" = "$default" ]; then
    echo "normal"
  else
    echo "custom"
  fi
}

cmd_reset() {
  local default_limit

  default_limit="$(get_default_limit)"

  echo "Resetting locked GPU clocks..."
  run_nvidia_smi -rgc

  echo "Restoring default power limit: ${default_limit} W"
  run_nvidia_smi -pl "$default_limit"

  echo
  echo "Done."
}

cmd_changed() {
  echo "Enabling persistence mode..."
  run_nvidia_smi -pm 1

  echo "Resetting locked GPU clocks..."
  run_nvidia_smi -rgc

  echo "Setting power limit to ${TARGET_POWER_LIMIT} W..."
  run_nvidia_smi -pl "$TARGET_POWER_LIMIT"

  echo
  echo "Done."
}

cmd_current() {
  local mode current_limit default_limit max_limit

  require_cmd

  mode="$(detect_mode)"
  current_limit="$(get_current_limit)"
  default_limit="$(get_default_limit)"
  max_limit="$(get_max_limit)"

  echo "summary:"
  nvidia-smi --query-gpu=name,pstate,temperature.gpu,power.draw,clocks.sm,utilization.gpu \
    --format=csv,noheader

  echo
  echo "power:"
  nvidia-smi -q -d POWER | sed -n '/GPU Power Readings/,/Power Samples/p' | sed '$d'

  echo
  echo "performance:"
  nvidia-smi -q -d PERFORMANCE | sed -n '/Performance State/,$p'

  echo
  echo "--"
  echo "mode-ish: ${mode}"
  echo "power-limit-ish: ${current_limit} W"
  echo "default-power-limit: ${default_limit} W"
  echo "max-power-limit: ${max_limit} W"

  if [ "$mode" = "custom" ]; then
    echo "note: current limit does not match default (${default_limit} W) or changed (${TARGET_POWER_LIMIT} W)"
  fi
}

cmd_list() {
  cat <<EOF
--normal
--default
--mid
--changed
--current
--list
--help
-h
EOF
}

main() {
  case "${1-}" in
    ""|--help|-h)
      usage
      ;;

    --normal|--default|--mid)
      shift
      [ "$#" -eq 0 ] || usage 1
      cmd_reset
      ;;

    --changed)
      shift
      [ "$#" -eq 0 ] || usage 1
      cmd_changed
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
