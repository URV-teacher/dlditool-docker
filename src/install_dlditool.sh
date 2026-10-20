#!/usr/bin/env bash
# Installs dlditool and the DLDI patch of the M3 / G6 / SuperCard CompactFlash (mpcf.dldi) into /URV/bmde/dlditool,
# and its environment (PATH) into /etc/profile.d/bmde-dlditool.sh. dlditool finds the patches given by name in its
# dldi/ directory. Can be run in an Ubuntu / Debian host from a checkout of the repository (after
# scripts/download_assets.sh), and is also used by the BMDE Docker images. Set BMDE_ROOT to install into another
# directory.
set -Eeuo pipefail

BMDE_ROOT="${BMDE_ROOT:-/URV/bmde}"
SUDO=""; if [ "$(id -u)" -ne 0 ]; then SUDO=sudo; fi
DLDITOOL_DIR="${BMDE_ROOT}/dlditool"
ASSETS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/../assets"

if [ ! -x "${DLDITOOL_DIR}/dlditool" ]; then
  for asset in dlditool-linux-x86_64.zip mpcf.dldi; do
    if [ ! -f "${ASSETS_DIR}/${asset}" ]; then
      echo "${ASSETS_DIR}/${asset} not found: download it with scripts/download_assets.sh" >&2
      exit 1
    fi
  done
  ${SUDO} apt-get update
  ${SUDO} apt-get install -y --no-install-recommends unzip
  ${SUDO} mkdir -p "${DLDITOOL_DIR}/dldi"
  ${SUDO} unzip -o "${ASSETS_DIR}/dlditool-linux-x86_64.zip" dlditool -d "${DLDITOOL_DIR}"
  ${SUDO} chmod +x "${DLDITOOL_DIR}/dlditool"
  ${SUDO} install -m 644 "${ASSETS_DIR}/mpcf.dldi" "${DLDITOOL_DIR}/dldi/mpcf.dldi"
fi

${SUDO} tee /etc/profile.d/bmde-dlditool.sh > /dev/null <<PROFILE
export DLDITOOL="${DLDITOOL_DIR}/dlditool"
case ":\${PATH}:" in
  *":${DLDITOOL_DIR}:"*) ;;
  *) export PATH="${DLDITOOL_DIR}:\${PATH}" ;;
esac
PROFILE

echo "dlditool installed in ${DLDITOOL_DIR}. Open a new session or run: . /etc/profile.d/bmde-dlditool.sh"
