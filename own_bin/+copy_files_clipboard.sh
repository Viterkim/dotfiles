#!/usr/bin/env bash
set -euo pipefail

IGNORE_NAMES=(
  ".git"
  ".gitmodules"
  ".gitattributes"
  ".github"
  ".gitlab"
  "node_modules"
  "vendor"
  ".pnpm-store"
  ".yarn"
  ".npm"
  "target"
  "dist"
  "build"
  "out"
  "release"
  "debug"
  ".output"
  "*.map"
  ".next"
  ".nuxt"
  ".svelte-kit"
  ".angular"
  ".expo"
  ".vercel"
  ".netlify"
  ".cache"
  ".turbo"
  ".parcel-cache"
  ".vite"
  ".eslintcache"
  "__pycache__"
  ".pytest_cache"
  ".mypy_cache"
  ".ruff_cache"
  ".cargo"
  ".gradle"
  ".env"
  ".env.local"
  ".direnv"
  ".idea"
  ".vscode"
  "tmp"
  "temp"
  "temp-out"
  "mock_fs"
  "mock-fs"
  "coverage"
  ".nyc_output"
  ".coverage"
  ".venv"
  "venv"
  ".terraform"
  "*.lock"
  "*lock.json"
  "*lock.yaml"
  "*.hex"
  "*.bin"
  "*.wasm"
  "*.exe"
  "*.dll"
  "*.so"
  "*.dylib"
  "*.min.js"
  "*.min.css"
  "*.png"
  "*.jpg"
  "*.jpeg"
  "*.gif"
  "*.webp"
  "*.svg"
  "*.mp4"
  "*.mov"
  "*.webm"
  "*.gguf"
  "*.ggml"
  "*.safetensors"
  "*.ckpt"
  "*.pt"
  "*.pth"
  "*.onnx"
  ".vibe-state"
)

usage() {
  echo "usage: +copy_files_clipboard.sh [-r] <file-or-directory>" >&2
  echo "  <file>        copy one file" >&2
  echo "  <directory>   copy files in directory" >&2
  echo "  -r            recurse into subdirectories" >&2
  exit 1
}

normalize_rel() {
  local rel="$1"
  rel="${rel#./}"
  printf '%s' "$rel"
}

print_summary_line() {
  local rel="$1"
  local lines="$2"
  local chars="$3"
  printf '%7s lines  %8s chars  %s\n' "$lines" "$chars" "$rel" >> "$SUMMARYFILE"
}

add_file_to_content() {
  local abs="$1"
  local rel="$2"

  FILE_COUNT=$((FILE_COUNT + 1))

  local lines chars
  lines=$(wc -l < "$abs" | tr -d ' ')
  chars=$(wc -c < "$abs" | tr -d ' ')

  TOTAL_LINES=$((TOTAL_LINES + lines))
  TOTAL_CHARS=$((TOTAL_CHARS + chars))

  print_summary_line "$rel" "$lines" "$chars"

  {
    echo "file: $rel"
    echo "  lines: $lines"
    echo "  chars: $chars"
    echo "---"
    cat -- "$abs"
    echo
    echo "---"
  } >> "$TMPFILE"
}

build_builtin_ignore_file() {
  : > "$BUILTIN_IGNORE_FILE"
  local pattern
  for pattern in "${IGNORE_NAMES[@]}"; do
    printf '%s\n' "$pattern" >> "$BUILTIN_IGNORE_FILE"
  done
}

build_rg_args() {
  RG_ARGS=(
    --files
    --hidden
    --no-ignore
    --no-require-git
    --null
    --color=never
    --ignore-file "$BUILTIN_IGNORE_FILE"
  )

  if [ -n "${1:-}" ] && [ -f "$1/.clipboardignore" ]; then
    RG_ARGS+=(--ignore-file "$1/.clipboardignore")
  fi

  if [ "$RECURSIVE" -ne 1 ]; then
    RG_ARGS+=(--max-depth 1)
  fi
}

RECURSIVE=0

while [ "${1:-}" != "" ]; do
  case "$1" in
    -r)
      RECURSIVE=1
      shift
      ;;
    -*)
      echo "unknown flag: $1" >&2
      usage
      ;;
    *)
      break
      ;;
  esac
done

TARGET="${1:-}"
[ -n "$TARGET" ] || usage

CLIPCOPY_BIN="$HOME/dotfiles/own_bin/+clipcopy.sh"
[ -f "$CLIPCOPY_BIN" ] || { echo "Clipboard helper not found: $CLIPCOPY_BIN" >&2; exit 1; }
[ -x "$CLIPCOPY_BIN" ] || { echo "Clipboard helper not executable: $CLIPCOPY_BIN" >&2; exit 1; }

command -v rg >/dev/null 2>&1 || { echo "rg is required" >&2; exit 1; }
command -v sort >/dev/null 2>&1 || { echo "sort is required" >&2; exit 1; }

FILE_COUNT=0
TOTAL_LINES=0
TOTAL_CHARS=0

TMPFILE="$(mktemp)"
SUMMARYFILE="$(mktemp)"
BUILTIN_IGNORE_FILE="$(mktemp)"
trap 'rm -f "$TMPFILE" "$SUMMARYFILE" "$BUILTIN_IGNORE_FILE"' EXIT INT TERM

build_builtin_ignore_file

if [ -f "$TARGET" ]; then
  TARGET_ABS="$(realpath "$TARGET")"
  TARGET_DIR="$(dirname "$TARGET_ABS")"
  TARGET_BASE="$(basename "$TARGET_ABS")"

  build_rg_args "$TARGET_DIR"

  included=0
  while IFS= read -r -d '' rel; do
    rel="$(normalize_rel "$rel")"
    if [ "$rel" = "$TARGET_BASE" ]; then
      included=1
      break
    fi
  done < <(
    cd "$TARGET_DIR"
    rg "${RG_ARGS[@]}" . | LC_ALL=C sort -z
  )

  if [ "$included" -ne 1 ]; then
    echo "Ignored by built-in rules or .clipboardignore: $TARGET" >&2
    exit 1
  fi

  add_file_to_content "$TARGET_ABS" "$TARGET_BASE"

elif [ -d "$TARGET" ]; then
  TARGET_ABS="$(realpath "$TARGET")"

  build_rg_args "$TARGET_ABS"

  while IFS= read -r -d '' rel; do
    rel="$(normalize_rel "$rel")"
    [ -n "$rel" ] || continue
    add_file_to_content "$TARGET_ABS/$rel" "$rel"
  done < <(
    cd "$TARGET_ABS"
    rg "${RG_ARGS[@]}" . | LC_ALL=C sort -z
  )

else
  echo "Not a regular file or directory: $TARGET" >&2
  exit 1
fi

if [ "$FILE_COUNT" -eq 0 ]; then
  echo "No files found in $TARGET" >&2
  exit 1
fi

CLIP="$("$CLIPCOPY_BIN" --backend)"
"$CLIPCOPY_BIN" < "$TMPFILE"

echo
echo "Included files:"
cat "$SUMMARYFILE"
echo
echo "Copied $FILE_COUNT file(s) to clipboard via $CLIP"
echo "Total lines: $TOTAL_LINES"
echo "Total chars: $TOTAL_CHARS"
