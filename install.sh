#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
PROJECT_NAME="${2:-WordPress Project}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: target directory not found: $TARGET_DIR" >&2
  exit 1
fi

cp "$SCRIPT_DIR/wp.sh" "$TARGET_DIR/wp.sh"
chmod +x "$TARGET_DIR/wp.sh"

TMP_FILE="$(mktemp)"
python3 - "$SCRIPT_DIR/AGENTS.md" "$PROJECT_NAME" "$TMP_FILE" <<'PY'
import pathlib
import sys

template_path = pathlib.Path(sys.argv[1])
project_name = sys.argv[2]
target_path = pathlib.Path(sys.argv[3])

content = template_path.read_text(encoding="utf-8")
content = content.replace("__PROJECT_NAME__", project_name)
target_path.write_text(content, encoding="utf-8")
PY
mv "$TMP_FILE" "$TARGET_DIR/AGENTS.md"

mkdir -p "$TARGET_DIR/tools"
cp "$SCRIPT_DIR/tools/media-import.sh" "$TARGET_DIR/tools/media-import.sh"
chmod +x "$TARGET_DIR/tools/media-import.sh"

echo "Installed in: $TARGET_DIR"
echo "- $TARGET_DIR/wp.sh"
echo "- $TARGET_DIR/AGENTS.md"
echo "- $TARGET_DIR/tools/media-import.sh (optional)"
