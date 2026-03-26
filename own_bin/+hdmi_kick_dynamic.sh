#!/usr/bin/env bash
set -euo pipefail

GR="${GNOME_RANDR_COMMAND:-gnome-randr}"
SLEEP_SECS="${KICK_SLEEP_SECS:-2}"
OUTPUT="${1:-${KICK_OUTPUT:-}}"

QUERY="$("$GR" query 2>/dev/null || "$GR")"

pick_output() {
    awk '
        function consider() {
            if (name != "" && has_current) {
                if (name !~ /^(eDP|LVDS|DSI)-/ && best == "")
                    best = name
                if (fallback == "")
                    fallback = name
            }
        }

        /^[^[:space:]]/ {
            consider()
            name = $1
            has_current = 0
            next
        }

        /^[[:space:]]+[0-9]+x[0-9]+@/ && /\*/ {
            has_current = 1
        }

        END {
            consider()
            if (best != "") print best
            else if (fallback != "") print fallback
        }
    ' <<<"$QUERY"
}

current_mode() {
    awk -v out="$OUTPUT" '
        /^[^[:space:]]/ {
            if ($1 == out) {
                in_block = 1
                next
            }
            if (in_block) exit
        }

        in_block && /^[[:space:]]+[0-9]+x[0-9]+@/ && /\*/ {
            print $1
            exit
        }
    ' <<<"$QUERY"
}

list_modes_for_res() {
    awk -v out="$OUTPUT" -v res="$1" '
        /^[^[:space:]]/ {
            if ($1 == out) {
                in_block = 1
                next
            }
            if (in_block) exit
        }

        in_block && /^[[:space:]]+[0-9]+x[0-9]+@/ {
            mode = $1
            if (mode ~ ("^" res "@"))
                print mode
        }
    ' <<<"$QUERY" | awk '!seen[$0]++' | sort -t@ -k2,2g
}

switch_mode() {
    local mode="$1"

    echo "Switching $OUTPUT -> $mode"
    if ! "$GR" modify "$OUTPUT" --mode "$mode"; then
        echo "Retrying $mode..."
        sleep 1
        "$GR" modify "$OUTPUT" --mode "$mode"
    fi
}

if [ -z "$OUTPUT" ]; then
    OUTPUT="$(pick_output)"
fi

if [ -z "$OUTPUT" ]; then
    echo "No active output found"
    exit 1
fi

CURRENT_MODE="$(current_mode)"
if [ -z "$CURRENT_MODE" ]; then
    echo "Could not detect current mode for $OUTPUT"
    exit 1
fi

RES="${CURRENT_MODE%@*}"

mapfile -t MODES < <(list_modes_for_res "$RES")

if [ "${#MODES[@]}" -lt 2 ]; then
    echo "Not enough same-resolution modes on $OUTPUT at $RES"
    echo "Current mode: $CURRENT_MODE"
    exit 1
fi

SAFE_MODE="${MODES[0]}"
MAX_MODE="${MODES[${#MODES[@]}-1]}"

echo "Output:       $OUTPUT"
echo "Current mode: $CURRENT_MODE"
echo "Resolution:   $RES"
echo "Safe mode:    $SAFE_MODE"
echo "Max mode:     $MAX_MODE"

if [ "$SAFE_MODE" = "$MAX_MODE" ]; then
    echo "Only one refresh mode exists at $RES"
    exit 1
fi

switch_mode "$SAFE_MODE"
sleep "$SLEEP_SECS"
switch_mode "$MAX_MODE"

echo "Done."
