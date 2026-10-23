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

# Builds the libfatdir example of devkitPro into the file $1, from the NDS examples of devkitPro at the version
# installed by devkitarm-nds-docker (src/install_examples.sh): with the local devkitARM if there is one (DEVKITARM), or
# else with the devkitARM image (DEVKITARM_IMAGE). The build is reproducible
# shellcheck disable=SC2329  # Called through a function: source of asset
build_libfatdir() {
  local example="filesystem/libfat/libfatdir" commit="54926f9f2d44ab0ea383acd524851837fd3c2998" build_dir build status=0
  build_dir="$(mktemp -d)"
  if [ -n "${DEVKITARM:-}" ] && [ -x "${DEVKITARM}/bin/arm-none-eabi-gcc" ]; then
    build=(make -C "${build_dir}/libfatdir")
  else
    build=(docker run --rm --user "$(id -u):$(id -g)" -v "${build_dir}/libfatdir:/libfatdir" --entrypoint bash
      "${DEVKITARM_IMAGE:-aleixmt/bmde-linux:latest}" -c "make -C /libfatdir")
  fi
  download "https://github.com/devkitPro/nds-examples/archive/${commit}.tar.gz" "${build_dir}/nds-examples.tar.gz" \
    && mkdir "${build_dir}/libfatdir" \
    && tar -xzf "${build_dir}/nds-examples.tar.gz" -C "${build_dir}/libfatdir" --strip-components 4 \
      "nds-examples-${commit}/${example}" \
    && "${build[@]}" \
    && cp "${build_dir}/libfatdir/libfatdir.nds" "$1" \
    || status=$?
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
