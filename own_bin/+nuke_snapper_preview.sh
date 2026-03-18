#!/usr/bin/env bash
set -euo pipefail

configs=("root" "home")
today=$(date +%F)

for c in "${configs[@]}"; do
    nums=$(sudo snapper -c "$c" list \
        | awk 'NR > 2 {print $1}' \
        | grep -v '^0$' \
        | xargs)

    if [ -z "$nums" ]; then
        echo "$c: (nothing to delete)"
    else
        echo "$c: $nums"
        echo
        echo "delete command:"
        echo
        echo "sudo snapper -c $c delete $nums"
    fi

    echo
done

echo "command to make new:"
echo
echo "sudo snapper -c root create --description \"Baseline - $today - Root Stable\" --cleanup-algorithm \"\""
echo "sudo snapper -c home create --description \"Baseline - $today - Home Stable\" --cleanup-algorithm \"\""
