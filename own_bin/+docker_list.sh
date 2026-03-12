#!/usr/bin/env bash
set -euo pipefail

echo "-- docker containers --"
sudo docker ps -a
echo ""
echo "-- docker images --"
sudo docker images
echo ""
