#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"${ROOT_DIR}/tools/setup_godot.sh" >/dev/null
"${ROOT_DIR}/tools/godot/bin/godot" --headless --path "${ROOT_DIR}" --import >/dev/null
"${ROOT_DIR}/tools/godot/bin/godot" --headless --path "${ROOT_DIR}"
