#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

export DEVICE=mz845
export VENDOR=meizu

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_TARGET=
SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-target )
                ONLY_TARGET=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        vendor/lib/vendor.qti.hardware.fm@1.0_vendor.so | vendor/lib64/vendor.qti.hardware.fm@1.0_vendor.so)
            grep -q libhidlbase_shim.so "{$2}" || patchelf --add-needed "libhidlbase_shim.so" "${2}"
            grep -q libbase_shim.so "{$2}" || patchelf --add-needed "libbase_shim.so" "${2}"
            ;;
        # vendor/lib/hw/android.hardware.bluetooth@1.0-impl-qti.so|vendor/lib64/hw/android.hardware.bluetooth@1.0-impl-qti.so)
        #     grep -q libhidlbase_shim.so "{$2}" || patchelf --add-needed "libhidlbase_shim.so" "${2}"
        #     grep -q libbase_shim.so "{$2}" || patchelf --add-needed "libbase_shim.so" "${2}"
        #     ;;
    esac
}

if [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi


"${MY_DIR}/setup-makefiles.sh"
