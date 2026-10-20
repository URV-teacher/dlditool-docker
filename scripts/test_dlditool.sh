#!/usr/bin/env bash
# Tests that dlditool is installed, patching a ROM that uses libfat (the libfatdir example of devkitPro) with the
# patch used by the course (mpcf.dldi).
#
# The ROM is built from the examples installed with devkitARM (devkitarm-nds-docker): with the local installation if
# there is one (DEVKITPRO), or else with the devkitARM image (DEVKITARM_IMAGE). Set LIBFATDIR_NDS to use an already
# built ROM instead, e.g. in a container without devkitARM or Docker.
set -Eeuo pipefail

DEVKITARM_IMAGE="${DEVKITARM_IMAGE:-aleixmt/bmde-linux:latest}"
# Relative to DEVKITPRO
LIBFATDIR_EXAMPLE="examples/nds/filesystem/libfat/libfatdir"

work_dir="$(mktemp -d)"
if [ -n "${LIBFATDIR_NDS:-}" ]; then
  cp "${LIBFATDIR_NDS}" "${work_dir}/test.nds"
elif [ -n "${DEVKITPRO:-}" ] && [ -d "${DEVKITPRO}/${LIBFATDIR_EXAMPLE}" ]; then
  cp -r "${DEVKITPRO}/${LIBFATDIR_EXAMPLE}" "${work_dir}/libfatdir"
  make -C "${work_dir}/libfatdir"
  cp "${work_dir}/libfatdir/libfatdir.nds" "${work_dir}/test.nds"
elif command -v docker > /dev/null; then
  # shellcheck disable=SC2016  # Expanded inside the container
  docker run --rm --user "$(id -u):$(id -g)" -v "${work_dir}:/output" --entrypoint bash "${DEVKITARM_IMAGE}" -c '
    set -e
    cp -r "${DEVKITPRO}/'"${LIBFATDIR_EXAMPLE}"'" /tmp/libfatdir
    make -C /tmp/libfatdir
    cp /tmp/libfatdir/libfatdir.nds /output/test.nds'
else
  echo "Cannot build the test ROM: install devkitARM or Docker, or set LIBFATDIR_NDS to an already built ROM" >&2
  exit 1
fi
(cd "${work_dir}" && dlditool mpcf.dldi test.nds) | tee "${work_dir}/dlditool.log"
grep -q "Patched successfully" "${work_dir}/dlditool.log"
rm -rf "${work_dir}"
