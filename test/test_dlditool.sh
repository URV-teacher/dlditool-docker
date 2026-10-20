#!/usr/bin/env bash
# Tests that dlditool is installed, patching a ROM that uses libfat (the libfatdir example of devkitPro) with the
# patch used by the course (mpcf.dldi).
set -Eeuo pipefail

# The libfatdir example of devkitPro, built by scripts/download_assets.sh
ROM="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/../assets/libfatdir.nds"

work_dir="$(mktemp -d)"
cp "${ROM}" "${work_dir}/test.nds"
(cd "${work_dir}" && dlditool mpcf.dldi test.nds) | tee "${work_dir}/dlditool.log"
grep -q "Patched successfully" "${work_dir}/dlditool.log"
rm -rf "${work_dir}"
