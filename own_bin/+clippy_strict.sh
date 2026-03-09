#!/usr/bin/env bash
set -euo pipefail

cargo clippy --release --all-targets --all-features -- -W clippy::all
