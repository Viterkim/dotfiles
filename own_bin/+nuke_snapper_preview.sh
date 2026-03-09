#!/usr/bin/env bash
set -euo pipefail

configs=("root" "home")

for c in "${configs[@]}"; do
    nums=$(sudo snapper -c "$c" list \
        | awk 'NR>2 {print $1}' \
        | grep -v '^0$' \
        | tr '\n' ' ')

    if [ -z "$nums" ]; then
        echo "$c: (nothing to delete)"
    else
        echo "$c: $nums"
        echo "delete command:"
        echo "sudo snapper -c $c delete $nums"
    fi

    echo
done
