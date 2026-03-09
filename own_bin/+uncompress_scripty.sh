#!/usr/bin/env bash
set -euo pipefail

for f in ./*; do
  case "$f" in
    *.gz.zst)
      echo "Extracting $f"
      gzip -dc "$f" | zstd -d -o "${f%.gz.zst}"
      ;;
    *.gz)
      echo "Extracting $f"
      gzip -d "$f"
      ;;
    *.zst)
      echo "Extracting $f"
      unzstd "$f"
      ;;
  esac
done
