#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="${SOURCEMOD_ARTIFACT_DIR:-$ROOT_DIR/dist/sourcemod/artifact}"

if [[ ! -d "$ARTIFACT_DIR" ]]; then
  echo "SourceMod artifact directory not found at $ARTIFACT_DIR" >&2
  exit 1
fi

python3 - "$ARTIFACT_DIR" <<'PY'
import os
import sys

artifact_dir = sys.argv[1]

plugin_path = os.path.join(artifact_dir, "addons", "sourcemod", "plugins", "AFKReadyup.smx")
if not os.path.isfile(plugin_path):
    raise SystemExit(f"Missing compiled plugin: {plugin_path}")

scripting_dir = os.path.join(artifact_dir, "addons", "sourcemod", "scripting")
for relative_path in [
    os.path.join("AFKReadyup.sp"),
    os.path.join("include", "afkreadyup.inc"),
]:
    path = os.path.join(scripting_dir, relative_path)
    if not os.path.isfile(path):
        raise SystemExit(f"Missing scripting artifact: {path}")

translations_dir = os.path.join(artifact_dir, "addons", "sourcemod", "translations")
for relative_path in [
    os.path.join("AFKReadyup.phrases.txt"),
    os.path.join("es", "AFKReadyup.phrases.txt"),
]:
    path = os.path.join(translations_dir, relative_path)
    if not os.path.isfile(path):
        raise SystemExit(f"Missing translation artifact: {path}")

compile_log = os.path.join(artifact_dir, "compile.log")
if not os.path.isfile(compile_log):
    raise SystemExit("Missing compile.log")

print("ARTIFACT_VALIDATION_OK")
PY