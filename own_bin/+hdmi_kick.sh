#!/usr/bin/env bash
set -euo pipefail

echo "Kicking HDMI-2..."

# Drop to 60Hz to force a modeset
gnome-randr modify HDMI-2 --mode 2560x1440@59.999

# Give the monitor a moment to handshake
sleep 2

# Slam it back to 360Hz native
gnome-randr modify HDMI-2 --mode 2560x1440@359.999

echo "Done."
