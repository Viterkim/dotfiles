#!/usr/bin/env bash
set -euo pipefail

cid="$(sudo docker ps --latest --quiet)"

if [ -z "$cid" ]; then
  echo "No recent container found" >&2
  exit 1
fi

exec sudo docker logs "$@" "$cid"
