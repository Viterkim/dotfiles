#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: copy_git_diff_clipboard.sh -a | -s | -u | -c <commit> | -b <branch> | -m" >&2
  echo "  -a            all changes (as if: git add -A; then diff vs HEAD / empty tree)" >&2
  echo "  -s            staged changes" >&2
  echo "  -u            unstaged changes" >&2
  echo "  -c <commit>   changes in a specific commit" >&2
  echo "  -b <branch>   diff against a specific branch" >&2
  echo "  -m            diff against main or master" >&2
  exit 1
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository" >&2
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

GIT_DIR="$(git rev-parse --git-dir)"
INDEX_PATH="${GIT_DIR%/}/index"

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
    CONTENT="$(git show --no-color "$TARGET")"
    LABEL="commit $TARGET"
    ;;

  branch)
    CONTENT="$(git diff --no-color "$TARGET")"
    LABEL="diff against $TARGET"
    ;;

  main_auto)
    # Check if 'main' exists, otherwise fallback to 'master'
    if git rev-parse --verify main >/dev/null 2>&1; then
      MAIN_BRANCH="main"
    else
      MAIN_BRANCH="master"
    fi
    CONTENT="$(git diff --no-color "$MAIN_BRANCH")"
    LABEL="diff against $MAIN_BRANCH"
    ;;

  all)
    LABEL="all changes"
    TMP_INDEX="$(mktemp)"
    RESTORE_INDEX="0"

    cleanup() {
      if [ "$RESTORE_INDEX" = "1" ]; then
        if [ -f "$TMP_INDEX" ]; then
          cp -f "$TMP_INDEX" "$INDEX_PATH" 2>/dev/null || true
        else
          rm -f "$INDEX_PATH" 2>/dev/null || true
        fi
      fi
      rm -f "$TMP_INDEX"
    }
    trap cleanup EXIT INT TERM

    if [ -f "$INDEX_PATH" ]; then
      cp -f "$INDEX_PATH" "$TMP_INDEX"
    fi

    RESTORE_INDEX="1"
    git add -A >/dev/null 2>&1

    if git rev-parse --verify HEAD >/dev/null 2>&1; then
      CONTENT="$(git diff --no-color --cached HEAD)"
    else
      EMPTY_TREE="$(git hash-object -t tree /dev/null)"
      CONTENT="$(git diff --no-color --cached "$EMPTY_TREE")"
    fi

    cleanup
    RESTORE_INDEX="0"
    trap - EXIT INT TERM
    ;;
esac

if [ -z "$CONTENT" ]; then
  echo "No $LABEL"
  exit 0
fi

TOTAL_LINES=$(printf "%s" "$CONTENT" | wc -l | tr -d ' ')
TOTAL_CHARS=$(printf "%s" "$CONTENT" | wc -c | tr -d ' ')

if command -v wl-copy >/dev/null 2>&1; then
  printf "%s" "$CONTENT" | wl-copy
  CLIP="wl-copy"
elif command -v xclip >/dev/null 2>&1; then
  printf "%s" "$CONTENT" | xclip -selection clipboard
  CLIP="xclip"
else
  echo "No clipboard tool found (need wl-copy or xclip)" >&2
  exit 1
fi

echo
echo "Copied $LABEL to clipboard via $CLIP"
echo "Total lines: $TOTAL_LINES"
echo "Total chars: $TOTAL_CHARS"
