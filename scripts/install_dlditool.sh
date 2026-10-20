#!/usr/bin/env bash
# Installs dlditool and the DLDI patch of the M3 / G6 / SuperCard CompactFlash (mpcf.dldi) into /URV/bmde/dlditool,
# and its environment (PATH) into /etc/profile.d/bmde-dlditool.sh. dlditool finds the patches given by name in its
# dldi/ directory. Standalone: can be run in an Ubuntu / Debian host, and is also used by the BMDE Docker images.
# Set BMDE_ROOT to install into another directory.
set -Eeuo pipefail

BMDE_ROOT="${BMDE_ROOT:-/URV/bmde}"
SUDO=""; if [ "$(id -u)" -ne 0 ]; then SUDO=sudo; fi
DLDITOOL_DIR="${BMDE_ROOT}/dlditool"

if [ ! -x "${DLDITOOL_DIR}/dlditool" ]; then
  ${SUDO} apt-get update
  ${SUDO} apt-get install -y --no-install-recommends ca-certificates wget unzip
  wget --no-check-certificate https://www.chishm.com/DLDI/downloads/dlditool-linux-x86_64.zip -O /tmp/dlditool.zip
  wget --no-check-certificate https://www.chishm.com/DLDI/downloads/mpcf.dldi -O /tmp/mpcf.dldi
  ${SUDO} mkdir -p "${DLDITOOL_DIR}/dldi"
  ${SUDO} unzip -o /tmp/dlditool.zip dlditool -d "${DLDITOOL_DIR}"
  ${SUDO} chmod +x "${DLDITOOL_DIR}/dlditool"
  ${SUDO} mv /tmp/mpcf.dldi "${DLDITOOL_DIR}/dldi/mpcf.dldi"
  rm -f /tmp/dlditool.zip
fi

${SUDO} tee /etc/profile.d/bmde-dlditool.sh > /dev/null <<PROFILE
export DLDITOOL="${DLDITOOL_DIR}/dlditool"
case ":\${PATH}:" in
  *":${DLDITOOL_DIR}:"*) ;;
  *) export PATH="${DLDITOOL_DIR}:\${PATH}" ;;
esac
PROFILE

echo "dlditool installed in ${DLDITOOL_DIR}. Open a new session or run: . /etc/profile.d/bmde-dlditool.sh"
