#!/usr/bin/env bash
set -euo pipefail

OUTPUT="${KICK_OUTPUT:-HDMI-2}"
SAFE_MODE="2560x1440@59.999"
FAST_MODE="2560x1440@359.999"

report_error() {
    local status=$?
    local message="HDMI kick failed (exit $status). Check: journalctl -t hdmi-kick"

    logger --tag hdmi-kick "$message"
    if command -v notify-send >/dev/null; then
        notify-send --urgency=critical "HDMI kick failed" "$message"
    fi
}
trap report_error ERR

switch_mode() {
    local mode="$1"

    logger --tag hdmi-kick "Switching $OUTPUT to $mode"
    gdctl set --logical-monitor --primary --monitor "$OUTPUT" --mode "$mode"
}

# Drop to 60Hz to force a modeset
switch_mode "$SAFE_MODE"

# Give the monitor a moment to handshake
sleep 2

# Slam it back to 360Hz native
switch_mode "$FAST_MODE"

logger --tag hdmi-kick "HDMI kick completed"
