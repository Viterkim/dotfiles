#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  local exit_code="${1:-0}"

  cat <<EOF
$SCRIPT_NAME

Apply a git patch to the repo you are currently standing in.

Usage:
  $SCRIPT_NAME <patch.diff>

What it does:
  - refuses if you're not inside a git repo
  - refuses if the repo is dirty
  - checks whether the patch can apply cleanly
  - applies it
  - shows changed files + diff stat

Notes:
  - the patch is applied to the current repo
  - changes are left unstaged, so you can inspect them first

Examples:
  $SCRIPT_NAME ~/tmp/fix.diff
  $SCRIPT_NAME ./my-change.diff

Nice flow:
  nvim something.diff
  paste patch
  save + quit
  $SCRIPT_NAME something.diff
EOF

  exit "$exit_code"
}

die() {
  echo "$*" >&2
  exit 1
}

print_status_block() {
  local repo_root="$1"

  echo
  echo "Changed files:"
  git -C "$repo_root" status --short
  echo
  echo "Diff stat:"
  git -C "$repo_root" diff --stat
}

if [[ "${1-}" == "-h" || "${1-}" == "--help" ]]; then
  usage 0
fi

if [ "$#" -eq 0 ]; then
  usage 0
fi

if [ "$#" -ne 1 ]; then
  echo "Expected exactly 1 argument." >&2
  echo >&2
  usage 1
fi

PATCH_FILE_INPUT="$1"

[ -f "$PATCH_FILE_INPUT" ] || die "Patch file not found: $PATCH_FILE_INPUT"
[ -r "$PATCH_FILE_INPUT" ] || die "Patch file is not readable: $PATCH_FILE_INPUT"

PATCH_FILE="$(realpath "$PATCH_FILE_INPUT" 2>/dev/null || true)"
[ -n "$PATCH_FILE" ] || die "Could not resolve patch file path: $PATCH_FILE_INPUT"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$REPO_ROOT" ] || die "Not inside a git repository"

DIRTY_STATUS="$(git -C "$REPO_ROOT" status --porcelain --untracked-files=all)"
if [ -n "$DIRTY_STATUS" ]; then
  echo "Repo is dirty. Commit, stash, or clean it first." >&2
  echo >&2
  git -C "$REPO_ROOT" status --short >&2
  exit 1
fi

echo "Repo:  $REPO_ROOT"
echo "Patch: $PATCH_FILE"

echo
echo "Checking patch..."
if ! git -C "$REPO_ROOT" apply --check --verbose "$PATCH_FILE"; then
  echo
  die "Patch did not pass preflight check"
fi

echo
echo "Applying patch..."
git -C "$REPO_ROOT" apply --verbose "$PATCH_FILE"

print_status_block "$REPO_ROOT"

echo
echo "Patch applied."
