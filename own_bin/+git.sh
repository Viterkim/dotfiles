#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

usage() {
  local exit_code="${1:-0}"

  cat <<EOF
$SCRIPT_NAME

Show a git diff for specific paths in the repo you are currently standing in.

Usage:
  $SCRIPT_NAME -l [-a | -s | -u | -c <commit> | -b <branch> | -m] [path ...]
  $SCRIPT_NAME -a [path ...]
  $SCRIPT_NAME -s [path ...]
  $SCRIPT_NAME -u [path ...]
  $SCRIPT_NAME -c <commit> [path ...]
  $SCRIPT_NAME -b <branch> [path ...]
  $SCRIPT_NAME -m [path ...]
  $SCRIPT_NAME [path ...]

If no path is given, "." is used.

Modes:
  -l            list changed files instead of printing the full diff
  -a            all changes (tracked + untracked), without touching your real index
  -s            staged changes
  -u            unstaged changes
  -c <commit>   combined diff from <commit> to HEAD
  -b <branch>   diff from merge-base(<branch>, HEAD) to HEAD
  -m            diff from merge-base(main/master, HEAD) to HEAD (default)
  -h, --help    show this help

Examples:
  $SCRIPT_NAME
  $SCRIPT_NAME -l
  $SCRIPT_NAME -m
  $SCRIPT_NAME -b main ./src/bingo.rs
  $SCRIPT_NAME ./src/bingo.rs
  $SCRIPT_NAME -c 4154146ebfeff41218b6ff096f3c455d36cc4029 ./pm2/src/integration_test/test/setup.rs
EOF

  exit "$exit_code"
}

die() {
  echo "$*" >&2
  exit 1
}

set_mode() {
  local next_mode="$1"
  local next_target="${2:-}"

  if [ -n "$MODE" ]; then
    die "Choose exactly one of -a, -s, -u, -c, -b, or -m"
  fi

  MODE="$next_mode"
  TARGET="$next_target"
}

require_commitish() {
  local rev="$1"

  if ! git rev-parse --verify "${rev}^{commit}" >/dev/null 2>&1; then
    die "Unknown revision: $rev"
  fi
}

normalize_pathspec() {
  local input="$1"
  local abs_path=""
  local rel_path=""

  if [[ "$input" == :* ]]; then
    printf '%s\n' "$input"
    return
  fi

  if [[ "$input" == /* ]]; then
    abs_path="$(realpath -m -- "$input")"
  else
    abs_path="$(realpath -m -- "$PWD/$input")"
  fi

  case "$abs_path" in
    "$REPO_ROOT")
      printf '%s\n' ':(top)'
      ;;
    "$REPO_ROOT"/*)
      rel_path="${abs_path#"$REPO_ROOT"/}"
      printf ':(top)%s\n' "$rel_path"
      ;;
    *)
      printf '%s\n' "$input"
      ;;
  esac
}

find_main_branch() {
  if git rev-parse --verify "main^{commit}" >/dev/null 2>&1; then
    printf '%s\n' "main"
  elif git rev-parse --verify "master^{commit}" >/dev/null 2>&1; then
    printf '%s\n' "master"
  else
    die "Could not find main or master"
  fi
}

build_color_args() {
  if [ -t 1 ]; then
    COLOR_ARGS=("--color=always")
  else
    COLOR_ARGS=("--color=never")
  fi
}

build_diff_args() {
  local main_branch=""
  local empty_tree=""

  case "$MODE" in
    unstaged)
      LABEL="unstaged changes"
      DIFF_ARGS=("--")
      ;;

    staged)
      LABEL="staged changes"
      DIFF_ARGS=("--staged" "--")
      ;;

    commit)
      require_commitish "$TARGET"
      LABEL="diff from $TARGET to HEAD"
      DIFF_ARGS=("$TARGET..HEAD" "--")
      ;;

    branch)
      require_commitish "$TARGET"
      LABEL="diff from merge-base($TARGET, HEAD) to HEAD"
      DIFF_ARGS=("$TARGET...HEAD" "--")
      ;;

    main_auto)
      main_branch="$(find_main_branch)"
      LABEL="diff from merge-base($main_branch, HEAD) to HEAD"
      DIFF_ARGS=("$main_branch...HEAD" "--")
      ;;

    all)
      LABEL="all changes"
      TMP_INDEX="$(mktemp)"
      rm -f "$TMP_INDEX"
      export GIT_INDEX_FILE="$TMP_INDEX"

      git add -A -- "${PATHS[@]}" >/dev/null 2>&1

      if git rev-parse --verify HEAD >/dev/null 2>&1; then
        DIFF_ARGS=("--cached" "HEAD" "--")
      else
        empty_tree="$(git hash-object -t tree /dev/null)"
        DIFF_ARGS=("--cached" "$empty_tree" "--")
      fi
      ;;
  esac
}

if [[ "${1-}" == "-h" || "${1-}" == "--help" ]]; then
  usage 0
fi

[ -n "$REPO_ROOT" ] || die "Not inside a git repository"

MODE=""
TARGET=""
LABEL=""
TMP_INDEX=""
DIFF_ARGS=()
COLOR_ARGS=()
LIST_ONLY=0

while getopts ":lasuc:b:mh" opt; do
  case "$opt" in
    l) LIST_ONLY=1 ;;
    a) set_mode "all" ;;
    s) set_mode "staged" ;;
    u) set_mode "unstaged" ;;
    c) set_mode "commit" "$OPTARG" ;;
    b) set_mode "branch" "$OPTARG" ;;
    m) set_mode "main_auto" ;;
    h) usage 0 ;;
    :) die "Missing argument for -$OPTARG" ;;
    *) usage 1 ;;
  esac
done

shift $((OPTIND - 1))

if [ -z "$MODE" ]; then
  MODE="main_auto"
fi

if [ "$#" -eq 0 ]; then
  RAW_PATHS=(".")
else
  RAW_PATHS=("$@")
fi

PATHS=()

for raw_path in "${RAW_PATHS[@]}"; do
  PATHS+=("$(normalize_pathspec "$raw_path")")
done

cleanup() {
  if [ -n "${TMP_INDEX:-}" ]; then
    rm -f "$TMP_INDEX"
  fi
}

trap cleanup EXIT INT TERM

build_color_args
build_diff_args

if git --no-pager diff --quiet "${DIFF_ARGS[@]}" "${PATHS[@]}"; then
  printf 'No %s for: %s\n' "$LABEL" "${RAW_PATHS[*]}"
  exit 0
fi

if [ "$LIST_ONLY" -eq 1 ]; then
  git --no-pager diff --name-only "${DIFF_ARGS[@]}" "${PATHS[@]}"
else
  git --no-pager diff "${COLOR_ARGS[@]}" "${DIFF_ARGS[@]}" "${PATHS[@]}"
fi
