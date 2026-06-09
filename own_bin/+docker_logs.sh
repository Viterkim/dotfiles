#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Usage:
  +docker_logs.sh [OPTIONS] [DOCKER_LOGS_ARGS...]

Show logs for the most recently created/running Docker container,
or for a specific container name/id.

Examples:
  +docker_logs.sh 
  +docker_logs.sh -f
  +docker_logs.sh -n my-container
  +docker_logs.sh --name my-container --tail 100
  +docker_logs.sh --follow
  +docker_logs.sh --tail 100
  +docker_logs.sh -f --tail 50
  +docker_logs.sh --since 10m

Notes:
  - Any arguments are passed straight to: docker logs
  - Without -n / --name, the target container is the latest one from: docker ps -lq
  - The value for -n / --name can be a container name or container id
  - So -f / --follow already works and will follow that container's logs

Common docker logs options:
  -f, --follow         Follow log output
      --tail N         Show only the last N lines
      --since TIME     Show logs since timestamp/duration
      --until TIME     Show logs before timestamp/duration
  -t, --timestamps     Show timestamps
      --details        Show extra details

Special:
  -n, --name VALUE     Use this container name or id
  -h, --help           Show this help
EOF
}

die() {
  echo "$*" >&2
  exit 1
}

container_ref=""
docker_logs_args=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -n|--name)
      [[ "$#" -ge 2 ]] || die "Missing value for $1"
      [[ -z "$container_ref" ]] || die "Container already specified with -n/--name"
      container_ref="$2"
      shift 2
      ;;
    --name=*)
      [[ -z "$container_ref" ]] || die "Container already specified with -n/--name"
      container_ref="${1#--name=}"
      [[ -n "$container_ref" ]] || die "Missing value for --name"
      shift
      ;;
    --)
      shift
      docker_logs_args+=("$@")
      break
      ;;
    *)
      docker_logs_args+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$container_ref" ]]; then
  sudo docker container inspect "$container_ref" >/dev/null 2>&1 \
    || die "Container not found: $container_ref"
else
  container_ref="$(sudo docker ps -lq)"
  [[ -n "$container_ref" ]] || die "No recent container found"
fi

exec sudo docker logs "${docker_logs_args[@]}" "$container_ref"
