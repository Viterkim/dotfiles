#!/usr/bin/env bash
set -euo pipefail

echo "Detecting HDMI output..."

OUTPUT="$(gnome-randr | awk '/^HDMI-[0-9]+ / {print $1; exit}')"

if [ -z "$OUTPUT" ]; then
    echo "No HDMI output found"
    exit 1
fi

echo "Using output: $OUTPUT"

CURRENT_MODE="$(gnome-randr | awk -v out="$OUTPUT" '
    $1 == out { in_block=1; next }
    in_block && /^[A-Za-z0-9-]+ / { exit }
    in_block && /\*/ { print $1; exit }
')"

if [ -z "$CURRENT_MODE" ]; then
    echo "Could not detect current mode for $OUTPUT"
    exit 1
fi

RES="${CURRENT_MODE%@*}"

echo "Current mode: $CURRENT_MODE"
echo "Detected resolution: $RES"

MAX_MODE="$(gnome-randr | awk -v out="$OUTPUT" -v res="$RES" '
    $1 == out { in_block=1; next }
    in_block && /^[A-Za-z0-9-]+ / { exit }
    in_block && $1 ~ ("^" res "@") { print $1 }
' | sort -t@ -k2,2nr | head -1)"

if [ -z "$MAX_MODE" ]; then
    echo "Could not detect max mode for $OUTPUT at $RES"
    exit 1
fi

SAFE_MODE="$(gnome-randr | awk -v out="$OUTPUT" -v res="$RES" '
    $1 == out { in_block=1; next }
    in_block && /^[A-Za-z0-9-]+ / { exit }
    in_block && $1 ~ ("^" res "@(59|60)\\.") { print $1; exit }
    in_block && $1 ~ ("^" res "@(59|60)$") { print $1; exit }
')"

echo "Max mode for current resolution: $MAX_MODE"

if [ -z "$SAFE_MODE" ]; then
    echo "Safe mode candidate: <not found>"
    exit 1
fi

echo "Safe mode candidate: $SAFE_MODE"

echo "Switching $OUTPUT to safe mode..."
gnome-randr modify "$OUTPUT" --mode "$SAFE_MODE"

echo "Waiting for handshake..."
sleep 2

echo "Restoring $OUTPUT to max mode..."
gnome-randr modify "$OUTPUT" --mode "$MAX_MODE"

echo "Done."
