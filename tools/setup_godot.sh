#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION=4.6.2
GODOT_TAG="${GODOT_VERSION}-stable"
GODOT_CHANNEL="stable"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${ROOT_DIR}/tools"
INSTALL_DIR="${TOOLS_DIR}/godot"
BIN_DIR="${INSTALL_DIR}/bin"
CACHE_DIR="${INSTALL_DIR}/cache"
GODOT_BIN="${BIN_DIR}/godot"

platform="$(uname -s)"
arch="$(uname -m)"

case "${platform}:${arch}" in
  Linux:x86_64)
    asset="Godot_v${GODOT_VERSION}-${GODOT_CHANNEL}_linux.x86_64.zip"
    extracted="Godot_v${GODOT_VERSION}-${GODOT_CHANNEL}_linux.x86_64"
    ;;
  *)
    echo "Unsupported platform for bootstrap: ${platform} ${arch}" >&2
    exit 1
    ;;
esac

url="https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/${asset}"
zip_path="${CACHE_DIR}/${asset}"

mkdir -p "${BIN_DIR}" "${CACHE_DIR}"

if [[ ! -x "${GODOT_BIN}" ]]; then
  if [[ ! -f "${zip_path}" ]]; then
    echo "Downloading Godot ${GODOT_TAG} from ${url}"
    curl -fL --retry 3 --output "${zip_path}" "${url}"
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' EXIT
  unzip -q "${zip_path}" -d "${tmp_dir}"
  install -m 0755 "${tmp_dir}/${extracted}" "${GODOT_BIN}"
fi

"${GODOT_BIN}" --version
