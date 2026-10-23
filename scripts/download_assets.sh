#!/usr/bin/env bash
# Downloads the assets of dlditool-docker into assets/.
#
# The download logic is the one shared by every component of the BMDE (download_lib.sh, copied from bmde: see it for
# the details). The external resources are listed in the documentation of bmde (docs/development/external-resources.md).
#
#   scripts/download_assets.sh [ASSET...]    (every asset by default)
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# shellcheck source=download_lib.sh
source "${SCRIPT_DIR}/download_lib.sh" "$@"

# Builds the libfatdir example of devkitPro into the file $1: with the local devkitARM if there is one (DEVKITPRO), or
# else with the devkitARM image (DEVKITARM_IMAGE), which installs the examples. The build is reproducible
# shellcheck disable=SC2329  # Called through a function: source of asset
build_libfatdir() {
  local example="examples/nds/filesystem/libfat/libfatdir" build_dir
  build_dir="$(mktemp -d)"
  if [ -n "${DEVKITPRO:-}" ] && [ -d "${DEVKITPRO}/${example}" ]; then
    cp -r "${DEVKITPRO}/${example}" "${build_dir}/libfatdir" && make -C "${build_dir}/libfatdir" \
      && cp "${build_dir}/libfatdir/libfatdir.nds" "$1"
  else
    # shellcheck disable=SC2016  # Expanded inside the container
    docker run --rm --user "$(id -u):$(id -g)" -v "${build_dir}:/output" --entrypoint bash \
      "${DEVKITARM_IMAGE:-aleixmt/bmde-linux:latest}" -c '
        set -e
        cp -r "${DEVKITPRO}/'"${example}"'" /tmp/libfatdir
        make -C /tmp/libfatdir
        cp /tmp/libfatdir/libfatdir.nds /output/' \
      && cp "${build_dir}/libfatdir.nds" "$1"
  fi
  local status=$?
  rm -rf "${build_dir}"
  return "${status}"
}

# dlditool and the DLDI driver of the course (M3 / G6 / SuperCard CompactFlash)
asset dlditool-linux-x86_64.zip 5853279aac8e5cb18711450d59b85298b98e68c92b06f60d1d7de858b2a0281f \
  "https://www.chishm.com/DLDI/downloads/dlditool-linux-x86_64.zip"
asset mpcf.dldi 9ad482e6520f631644a808ef53d5a35f55223ebe3d6d2754c94329ba04585a86 \
  "https://www.chishm.com/DLDI/downloads/mpcf.dldi"
# ROM patched by test_dlditool.sh: the libfatdir example of devkitPro, which uses libfat, so it has a DLDI section
asset libfatdir.nds 88877aa85996fd6dc890b5d54c49797b06dd40b5d14cf13afcd14a327c5b76ef function:build_libfatdir

exit "${failed}"
