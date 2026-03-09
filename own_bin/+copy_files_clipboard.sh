#!/usr/bin/env bash
set -euo pipefail

RECURSIVE=0

IGNORE_NAMES=(
  # vcs
  ".git"
  ".gitignore"
  ".gitmodules"
  ".gitattributes"
  ".github"
  ".gitlab"

  # dependency
  "node_modules"
  "vendor"
  ".pnpm-store"
  ".yarn"
  ".npm"

  # build
  "target"
  "dist"
  "build"
  "out"
  "release"
  "debug"
  ".output"
  "*.map"

  # frameworks
  ".next"
  ".nuxt"
  ".svelte-kit"
  ".angular"
  ".expo"

  # deploy
  ".vercel"
  ".netlify"

  # cache
  ".cache"
  ".turbo"
  ".parcel-cache"
  ".vite"
  ".eslintcache"

  # python
  "__pycache__"
  ".pytest_cache"
  ".mypy_cache"
  ".ruff_cache"

  # rust
  ".cargo"

  # java
  ".gradle"

  # env
  ".env"
  ".env.local"
  ".direnv"

  # editors
  ".idea"
  ".vscode"

  # temp
  "tmp"
  "temp"
  "temp-out"

  # testing
  "mock_fs"
  "mock-fs"
  "coverage"
  ".nyc_output"
  ".coverage"

  # python env
  ".venv"
  "venv"

  # infra
  ".terraform"

  # locks
  "*.lock"
  "*lock.json"
  "*lock.yaml"

  # binaries
  "*.hex"
  "*.bin"
  "*.wasm"
  "*.exe"
  "*.dll"
  "*.so"
  "*.dylib"

  # minified
  "*.min.js"
  "*.min.css"

  # media
  "*.png"
  "*.jpg"
  "*.jpeg"
  "*.gif"
  "*.webp"
  "*.svg"
  "*.mp4"
  "*.mov"
  "*.webm"

  # misc
  ".DS_Store"
)

usage() {
  echo "usage: copy-files-clipboard.sh [-r] <directory>" >&2
  exit 1
}

build_find_cmd() {
  local dir="$1"
  local -a cmd=()

  cmd+=(find "$dir")

  if [ "$RECURSIVE" -ne 1 ]; then
    cmd+=(-maxdepth 1)
  fi

  cmd+=("(")

  local first=1
  local pattern
  for pattern in "${IGNORE_NAMES[@]}"; do
    if [ "$first" -eq 0 ]; then
      cmd+=(-o)
    fi
    cmd+=(-name "$pattern")
    first=0
  done

  cmd+=(")" -prune -o -type f -print0)

  printf '%s\0' "${cmd[@]}"
}

# Parse flags
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

DIR="${1:-}"

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  usage
fi

FILE_COUNT=0
TOTAL_LINES=0
TOTAL_CHARS=0
CONTENT=""

# Build find command safely as an array
mapfile -d '' -t FIND_CMD < <(build_find_cmd "$DIR")

# Collect files safely, preserving weird filenames
mapfile -d '' -t FILES < <("${FIND_CMD[@]}" | sort -z)

for f in "${FILES[@]}"; do
  FILE_COUNT=$((FILE_COUNT + 1))

  LINES=$(wc -l < "$f" | tr -d ' ')
  CHARS=$(wc -c < "$f" | tr -d ' ')

  TOTAL_LINES=$((TOTAL_LINES + LINES))
  TOTAL_CHARS=$((TOTAL_CHARS + CHARS))

  echo "file: $f"
  echo "  lines: $LINES"
  echo "  chars: $CHARS"

  CONTENT+="===== $f =====
$(cat -- "$f")

"
done

if [ "$FILE_COUNT" -eq 0 ]; then
  echo "No files found in $DIR" >&2
  exit 1
fi

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
echo "Copied $FILE_COUNT files to clipboard via $CLIP"
echo "Total lines: $TOTAL_LINES"
echo "Total chars: $TOTAL_CHARS"
