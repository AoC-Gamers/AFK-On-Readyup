#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <version> <output-file>" >&2
  exit 1
fi

VERSION="$1"
OUTPUT_FILE="$2"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"

if [[ ! -f "$CHANGELOG_FILE" ]]; then
  echo "CHANGELOG.md not found at $CHANGELOG_FILE" >&2
  exit 1
fi

python3 - "$CHANGELOG_FILE" "$VERSION" "$OUTPUT_FILE" <<'PY'
import pathlib
import re
import sys

changelog_path = pathlib.Path(sys.argv[1])
version = sys.argv[2]
output_path = pathlib.Path(sys.argv[3])

text = changelog_path.read_text(encoding="utf-8")
pattern = re.compile(
  rf"^## \[{re.escape(version)}\](?:\s+-\s+[^\r\n]+)?\r?\n(?P<body>.*?)(?=^## \[|\Z)",
    re.MULTILINE | re.DOTALL,
)
match = pattern.search(text)
if not match:
    raise SystemExit(f"Version {version} not found in CHANGELOG.md")

body = match.group("body").strip()
if not body:
    raise SystemExit(f"Version {version} has no release notes in CHANGELOG.md")

output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(body + "\n", encoding="utf-8")
PY