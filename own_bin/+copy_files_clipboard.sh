#!/usr/bin/env bash
set -euo pipefail

RECURSIVE=0
TARGET="${1:-}"
CLIPCOPY_BIN="$HOME/dotfiles/own_bin_helpers/clipcopy.sh"

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
  ".clipboardignore"
  ".*ignore"

  # ai artifacts
  "*.gguf"
  "*.ggml"
  "*.safetensors"
  "*.ckpt"
  "*.pt"
  "*.pth"
  "*.onnx"
)

EXTRA_IGNORE_PATTERNS=()

usage() {
  echo "usage: copy-files-clipboard.sh [-r] <file-or-directory>" >&2
  echo "  <file>        copy one file" >&2
  echo "  <directory>   copy files in directory" >&2
  echo "  -r            recurse into subdirectories" >&2
  exit 1
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

load_ignore_file() {
  local file="$1"
  [ -f "$file" ] || return 0

  local line
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    line="$(trim "$line")"

    [ -z "$line" ] && continue
    [[ "$line" == \#* ]] && continue
    [[ "$line" == '//'* ]] && continue

    EXTRA_IGNORE_PATTERNS+=("$line")
  done < "$file"
}

matches_extra_ignore() {
  local rel="$1"
  local pat="$2"
  local base="${rel##*/}"

  pat="${pat#./}"

  if [[ "$pat" == /* ]]; then
    pat="${pat#/}"

    if [[ "$pat" == */ ]]; then
      pat="${pat%/}"
      [[ "$rel" == "$pat"/* || "$rel" == "$pat" ]] && return 0
      return 1
    fi

    [[ "$rel" == $pat ]] && return 0
    return 1
  fi

  if [[ "$pat" == */ ]]; then
    pat="${pat%/}"
    [[ "$rel" == "$pat"/* || "$rel" == */"$pat"/* || "$rel" == "$pat" || "$rel" == */"$pat" ]] && return 0
    return 1
  fi

  if [[ "$pat" == *"/"* ]]; then
    [[ "$rel" == $pat || "$rel" == */$pat ]] && return 0
    return 1
  fi

  [[ "$base" == $pat ]] && return 0
  [[ "$rel" == $pat ]] && return 0

  return 1
}

should_ignore_file() {
  local rel="$1"

  local pat
  for pat in "${EXTRA_IGNORE_PATTERNS[@]}"; do
    if matches_extra_ignore "$rel" "$pat"; then
      return 0
    fi
  done

  return 1
}

is_ignored_by_name() {
  local path="$1"
  local base
  base="$(basename "$path")"

  local pattern
  for pattern in "${IGNORE_NAMES[@]}"; do
    if [[ "$base" == $pattern ]]; then
      return 0
    fi
  done

  return 1
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

add_file_to_content() {
  local f="$1"
  local rel="$2"

  if should_ignore_file "$rel"; then
    return 0
  fi

  FILE_COUNT=$((FILE_COUNT + 1))

  local lines chars
  lines=$(wc -l < "$f" | tr -d ' ')
  chars=$(wc -c < "$f" | tr -d ' ')

  TOTAL_LINES=$((TOTAL_LINES + lines))
  TOTAL_CHARS=$((TOTAL_CHARS + chars))

  echo "file: $f"
  echo "  lines: $lines"
  echo "  chars: $chars"

  CONTENT+="===== $f =====
$(cat -- "$f")

"
}

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

if [ -z "$TARGET" ]; then
  usage
fi

if [ ! -e "$TARGET" ]; then
  echo "Not found: $TARGET" >&2
  exit 1
fi

if [ ! -x "$CLIPCOPY_BIN" ]; then
  echo "Clipboard helper not found or not executable: $CLIPCOPY_BIN" >&2
  exit 1
fi

FILE_COUNT=0
TOTAL_LINES=0
TOTAL_CHARS=0
CONTENT=""

if [ -f "$TARGET" ]; then
  if is_ignored_by_name "$TARGET"; then
    echo "Ignored by built-in ignore rules: $TARGET" >&2
    exit 1
  fi

  parent_dir="$(dirname "$TARGET")"
  rel_name="$(basename "$TARGET")"

  load_ignore_file "$parent_dir/.gitignore"
  load_ignore_file "$parent_dir/.clipboardignore"

  add_file_to_content "$TARGET" "$rel_name"

elif [ -d "$TARGET" ]; then
  load_ignore_file "$TARGET/.gitignore"
  load_ignore_file "$TARGET/.clipboardignore"

  mapfile -d '' -t FIND_CMD < <(build_find_cmd "$TARGET")
  mapfile -d '' -t FILES < <("${FIND_CMD[@]}" | sort -z)

  for f in "${FILES[@]}"; do
    rel="${f#"$TARGET"/}"
    [ "$rel" = "$f" ] && rel="$(basename "$f")"
    add_file_to_content "$f" "$rel"
  done
else
  echo "Not a regular file or directory: $TARGET" >&2
  exit 1
fi

if [ "$FILE_COUNT" -eq 0 ]; then
  echo "No files found in $TARGET" >&2
  exit 1
fi

CLIP="$("$CLIPCOPY_BIN" --backend)"
printf "%s" "$CONTENT" | "$CLIPCOPY_BIN"

echo
echo "Copied $FILE_COUNT file(s) to clipboard via $CLIP"
echo "Total lines: $TOTAL_LINES"
echo "Total chars: $TOTAL_CHARS"
