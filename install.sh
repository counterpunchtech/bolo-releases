#!/usr/bin/env sh
# Bolo headless installer.
#
# Usage:
#   curl -sSL https://get.bolo.app | sh
#   curl -sSL https://raw.githubusercontent.com/counterpunchtech/bolo-releases/main/install.sh | sh
#
# Environment overrides:
#   BOLO_CHANNEL=stable|beta|nightly   (default: stable)
#   BOLO_INSTALL_DIR=<path>            (default: ~/.local/share/bolo/bin on Linux,
#                                       ~/Library/Application Support/app.bolo.desktop/bin on macOS)
#   BOLO_VERSION=vX.Y.Z                (default: latest in channel)

set -eu

CHANNEL="${BOLO_CHANNEL:-stable}"
REPO="counterpunchtech/bolo-releases"
MANIFEST_BASE="https://raw.githubusercontent.com/${REPO}/main/${CHANNEL}"
PUBKEY_URL="https://raw.githubusercontent.com/${REPO}/main/pubkeys/bolod.pub"

uname_s=$(uname -s)
uname_m=$(uname -m)

case "${uname_s}-${uname_m}" in
  Darwin-arm64)  TRIPLE="aarch64-apple-darwin" ;;
  Darwin-x86_64) TRIPLE="x86_64-apple-darwin" ;;
  Linux-aarch64) TRIPLE="aarch64-unknown-linux-gnu" ;;
  Linux-x86_64)  TRIPLE="x86_64-unknown-linux-gnu" ;;
  *) echo "error: unsupported platform ${uname_s}-${uname_m}" >&2; exit 1 ;;
esac

case "${uname_s}" in
  Darwin) DEFAULT_DIR="${HOME}/Library/Application Support/app.bolo.desktop/bin" ;;
  Linux)  DEFAULT_DIR="${HOME}/.local/share/bolo/bin" ;;
esac
INSTALL_DIR="${BOLO_INSTALL_DIR:-${DEFAULT_DIR}}"

command -v curl >/dev/null 2>&1 || { echo "error: curl required" >&2; exit 1; }
command -v minisign >/dev/null 2>&1 || {
  echo "error: minisign required (https://jedisct1.github.io/minisign/)" >&2
  echo "  macOS:  brew install minisign" >&2
  echo "  Linux:  apt install minisign  or  cargo install rsign2" >&2
  exit 1
}

tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT

echo "fetching manifest for channel=${CHANNEL} triple=${TRIPLE}..."
curl -fsSLo "${tmp}/manifest.json"          "${MANIFEST_BASE}/bolod-latest.json"
curl -fsSLo "${tmp}/manifest.json.minisig"  "${MANIFEST_BASE}/bolod-latest.json.minisig"
curl -fsSLo "${tmp}/bolod.pub"              "${PUBKEY_URL}"

minisign -Vm "${tmp}/manifest.json" -p "${tmp}/bolod.pub" >/dev/null
echo "manifest signature OK."

url=$(grep -o "\"url\"[[:space:]]*:[[:space:]]*\"[^\"]*${TRIPLE}[^\"]*\"" "${tmp}/manifest.json" \
  | head -1 | sed 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
[ -n "${url}" ] || { echo "error: no artifact for ${TRIPLE} in manifest" >&2; exit 1; }

echo "downloading ${url}..."
curl -fsSLo "${tmp}/artifact.tar.gz"          "${url}"
curl -fsSLo "${tmp}/artifact.tar.gz.minisig"  "${url}.minisig"

minisign -Vm "${tmp}/artifact.tar.gz" -p "${tmp}/bolod.pub" >/dev/null
echo "artifact signature OK."

mkdir -p "${INSTALL_DIR}"
tar -C "${INSTALL_DIR}" -xzf "${tmp}/artifact.tar.gz"
chmod +x "${INSTALL_DIR}/bolod" 2>/dev/null || true

echo
echo "installed to: ${INSTALL_DIR}"
echo "next:"
echo "  export PATH=\"\${PATH}:${INSTALL_DIR}\""
echo "  bolod --version"
