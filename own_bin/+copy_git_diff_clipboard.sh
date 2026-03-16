#!/usr/bin/env bash
set -euo pipefail

CLIPCOPY_BIN="$HOME/dotfiles/own_bin_helpers/clipcopy.sh"

usage() {
  echo "usage: copy_git_diff_clipboard.sh -a | -s | -u | -c <commit> | -b <branch> | -m" >&2
  echo "  -a            all changes (tracked + untracked), without touching your real index" >&2
  echo "  -s            staged changes" >&2
  echo "  -u            unstaged changes" >&2
  echo "  -c <commit>   combined diff from <commit> to HEAD" >&2
  echo "  -b <branch>   diff from merge-base(<branch>, HEAD) to HEAD" >&2
  echo "  -m            diff from merge-base(main/master, HEAD) to HEAD" >&2
  exit 1
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository" >&2
  exit 1
fi

if [ ! -x "$CLIPCOPY_BIN" ]; then
  echo "Clipboard helper not found or not executable: $CLIPCOPY_BIN" >&2
  exit 1
fi

MODE=""
TARGET=""

while getopts "asuc:b:m" opt; do
  case "$opt" in
    a) MODE="all" ;;
    s) MODE="staged" ;;
    u) MODE="unstaged" ;;
    c) MODE="commit"; TARGET="$OPTARG" ;;
    b) MODE="branch"; TARGET="$OPTARG" ;;
    m) MODE="main_auto" ;;
    *) usage ;;
  esac
done

shift $((OPTIND - 1))
if [ -z "${MODE}" ] || [ "${#}" -ne 0 ]; then
  usage
fi

require_commitish() {
  local rev="$1"
  if ! git rev-parse --verify "${rev}^{commit}" >/dev/null 2>&1; then
    echo "Unknown revision: $rev" >&2
    exit 1
  fi
}

CONTENT=""
LABEL=""

case "$MODE" in
  unstaged)
    CONTENT="$(git diff --no-color)"
    LABEL="unstaged changes"
    ;;

  staged)
    CONTENT="$(git diff --no-color --staged)"
    LABEL="staged changes"
    ;;

  commit)
    require_commitish "$TARGET"
    CONTENT="$(git diff --no-color "$TARGET..HEAD")"
    LABEL="diff from $TARGET to HEAD"
    ;;

  branch)
    require_commitish "$TARGET"
    CONTENT="$(git diff --no-color "$TARGET...HEAD")"
    LABEL="diff from merge-base($TARGET, HEAD) to HEAD"
    ;;

  main_auto)
    if git rev-parse --verify "main^{commit}" >/dev/null 2>&1; then
      MAIN_BRANCH="main"
    elif git rev-parse --verify "master^{commit}" >/dev/null 2>&1; then
      MAIN_BRANCH="master"
    else
      echo "Could not find main or master" >&2
      exit 1
    fi

    CONTENT="$(git diff --no-color "$MAIN_BRANCH...HEAD")"
    LABEL="diff from merge-base($MAIN_BRANCH, HEAD) to HEAD"
    ;;

  all)
    LABEL="all changes"

    TMP_INDEX="$(mktemp)"
    cleanup() {
      rm -f "$TMP_INDEX"
    }
    trap cleanup EXIT INT TERM

    export GIT_INDEX_FILE="$TMP_INDEX"
    git add -A >/dev/null 2>&1

    if git rev-parse --verify HEAD >/dev/null 2>&1; then
      CONTENT="$(git diff --no-color --cached HEAD)"
    else
      EMPTY_TREE="$(git hash-object -t tree /dev/null)"
      CONTENT="$(git diff --no-color --cached "$EMPTY_TREE")"
    fi

    unset GIT_INDEX_FILE
    cleanup
    trap - EXIT INT TERM
    ;;
esac

if [ -z "$CONTENT" ]; then
  echo "No $LABEL"
  exit 0
fi

TOTAL_LINES=$(printf "%s" "$CONTENT" | wc -l | tr -d ' ')
TOTAL_CHARS=$(printf "%s" "$CONTENT" | wc -c | tr -d ' ')

CLIP="$("$CLIPCOPY_BIN" --backend)"
printf "%s" "$CONTENT" | "$CLIPCOPY_BIN"

echo
echo "Copied $LABEL to clipboard via $CLIP"
echo "Total lines: $TOTAL_LINES"
echo "Total chars: $TOTAL_CHARS"
