#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Usage:
  +docker_logs.sh [OPTIONS] [DOCKER_LOGS_ARGS...]

Show logs for the most recently created/running Docker container.

Examples:
  +docker_logs.sh 
  +docker_logs.sh -f
  +docker_logs.sh --follow
  +docker_logs.sh --tail 100
  +docker_logs.sh -f --tail 50
  +docker_logs.sh --since 10m

Notes:
  - Any arguments are passed straight to: docker logs
  - The target container is always the latest one from: docker ps -lq
  - So -f / --follow already works and will follow that container's logs

Common docker logs options:
  -f, --follow         Follow log output
      --tail N         Show only the last N lines
      --since TIME     Show logs since timestamp/duration
      --until TIME     Show logs before timestamp/duration
  -t, --timestamps     Show timestamps
      --details        Show extra details

Special:
  -h, --help           Show this help
EOF
}

case "${1-}" in
  -h|--help)
    show_help
    exit 0
    ;;
esac

cid="$(sudo docker ps -lq)"

if [[ -z "$cid" ]]; then
  echo "No recent container found" >&2
  exit 1
fi

exec sudo docker logs "$@" "$cid"
