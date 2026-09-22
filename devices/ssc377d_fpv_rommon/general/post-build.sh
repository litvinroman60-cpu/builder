#!/bin/sh
set -eu

# SSC377D/IMX335 uses the stock OpenIPC ISP profile. Do not download or inject
# Greg/SSC338Q-specific ISP binaries into this target. The known SSC377D+IMX335
# reference path loads /etc/sensors/imx335.bin.

SENSORS_DIR="$TARGET_DIR/etc/sensors"
mkdir -p "$SENSORS_DIR"

# Remove any Greg/experimental IMX335 profiles that may have been copied by a
# generic package or an earlier build. Keep the stock imx335.bin untouched.
find "$SENSORS_DIR" -maxdepth 1 -type f \
    \( -name 'imx335_greg*.bin' -o -name 'imx335_spike*.bin' \) -delete

if [ ! -s "$SENSORS_DIR/imx335.bin" ]; then
    echo "WARNING: /etc/sensors/imx335.bin is not present in the target rootfs" >&2
fi
