#!/bin/sh
set -eu

# Pin the known OpenIPC Greg IMX335 ISP profile to a reviewed commit.
# The profile is a binary asset, so it is fetched at build time rather than
# stored through the text-only GitHub connector.
PROFILE_URL="https://raw.githubusercontent.com/OpenIPC/sensor-profiles/24fc1486099f1afc01a78bcd28971e8a58e8fe2d/files/imx335_greg15.bin"
PROFILE="$TARGET_DIR/etc/sensors/imx335_greg15.bin"

mkdir -p "$(dirname "$PROFILE")"

if command -v wget >/dev/null 2>&1; then
    wget -q -O "$PROFILE" "$PROFILE_URL"
elif command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$PROFILE" "$PROFILE_URL"
else
    echo "ERROR: wget or curl is required to fetch the Greg IMX335 ISP profile" >&2
    exit 1
fi

[ -s "$PROFILE" ] || {
    echo "ERROR: downloaded Greg IMX335 ISP profile is empty" >&2
    exit 1
}

chmod 0644 "$PROFILE"

# Keep only the profile used by this target if a previous build copied a
# generic/alternative IMX335 profile into the target rootfs.
find "$TARGET_DIR/etc/sensors" -maxdepth 1 -type f \
    \( -name 'imx335_greg*.bin' -o -name 'imx335_spike*.bin' \) \
    ! -name 'imx335_greg15.bin' -delete
