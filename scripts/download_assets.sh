#!/usr/bin/env bash
# Downloads the assets of dlditool-docker.
#
# Downloads the assets needed to build and test the component into assets/, the only place from where its install
# scripts (src/) and its tests (test/) take them: building never accesses external systems. For each asset: if it is
# already in assets/, checks its SHA-256; if it is not, downloads it and then checks its SHA-256. The assets that are
# always the latest version of their source have no pinned SHA-256, so they are downloaded but not checked. Fails if
# any asset could not be downloaded or does not match its SHA-256. The external resources are listed in the
# documentation of bmde (docs/development/external-resources.md).
#
#   scripts/download_assets.sh [ASSET...]    (every asset by default)
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ASSETS_DIR="${SCRIPT_DIR}/../assets"
SELECTED=" $* "
failed=0

# Downloads the URL $1 into the file $2
download() {
  if command -v wget > /dev/null; then
    wget -q "$1" -O "$2"
  else
    curl -fsSL "$1" -o "$2"
  fi
}

# Obtains the source $1 into the file $2: a URL, or function:NAME to make it with the function NAME (given the file)
obtain() {
  case "$1" in
    function:*) "${1#function:}" "$2" ;;
    *) download "$1" "$2" ;;
  esac
}

# SHA-256 of the file $1
checksum() {
  sha256sum "$1" | cut -d ' ' -f 1
}

# asset NAME SHA256 SOURCE...: makes sure that assets/NAME is there and has the SHA-256 SHA256 (empty if it is not
# pinned). If it is not there, it is obtained from the first SOURCE that works. An asset without SOURCE is stored in
# the repository, so it is only checked
asset() {
  local name="$1" sha256="$2" file="${ASSETS_DIR}/$1" source actual
  shift 2
  if [ "${SELECTED}" != "  " ] && [[ "${SELECTED}" != *" ${name} "* ]]; then
    return 0
  fi
  if [ -f "${file}" ]; then
    echo "${name}: present"
  else
    mkdir -p "$(dirname "${file}")"
    for source in "$@"; do
      echo "${name}: downloading from ${source}"
      if obtain "${source}" "${file}.part"; then
        mv "${file}.part" "${file}"
        break
      fi
      rm -f "${file}.part"
      echo "${name}: could not be downloaded from ${source}" >&2
    done
    if [ ! -f "${file}" ] && [ "$#" -eq 0 ]; then
      echo "${name}: ERROR, missing (it is stored in the repository: restore it with git)" >&2
      failed=1
      return 0
    elif [ ! -f "${file}" ]; then
      echo "${name}: ERROR, could not be downloaded" >&2
      failed=1
      return 0
    fi
  fi
  if [ -z "${sha256}" ]; then
    echo "${name}: not checked (latest version, without pinned SHA-256)"
    return 0
  fi
  actual="$(checksum "${file}")"
  if [ "${actual}" = "${sha256}" ]; then
    echo "${name}: OK, the SHA-256 matches"
  else
    echo "${name}: ERROR, the SHA-256 does not match (expected ${sha256}, got ${actual}). Delete it to download it" \
      "again" >&2
    failed=1
  fi
}

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
