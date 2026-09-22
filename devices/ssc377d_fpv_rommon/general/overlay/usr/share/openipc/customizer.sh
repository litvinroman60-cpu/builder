#!/bin/sh
#
# SSC377D FPV first-boot configuration
#
# Keep the image aligned with the working PixelPilot/WFB setup while avoiding
# wifibroadcast's generic first-boot video_settings() override.
#
fw_setenv upgrade 'https://github.com/OpenIPC/builder/releases/download/latest/ssc377d_fpv.tgz'

# Video profile for PixelPilot / WFB-NG.
cli -s .video0.size 1280x720
cli -s .video0.fps 60
cli -s .video0.bitrate 6144
cli -s .video0.codec h265
cli -s .video0.rcMode cbr
cli -s .outgoing.wfb true
cli -s .records.split 1
cli -s .records.notime true
cli -s .fpv.enabled true

# Greg Sparks IMX335 FPV ISP profile.
# OpenIPC ships this profile as imx335_greg15.bin and exposes it in the FPV
# camera menu. The newer waybeam Greg FPV VII profile is documented for
# Star6E/SSC338Q; we deliberately use the packaged Greg15 profile here because
# it is an actual released binary from OpenIPC/sensor-profiles and is not tied
# to the SSC338Q/waybeam test target.
cli -s .isp.sensorConfig /etc/sensors/imx335_greg15.bin
cli -s .isp.exposure 16

# Preserve the known-working RTL8812AU/WFB parameters.
wifibroadcast cli -s .wireless.channel 161
wifibroadcast cli -s .wireless.txpower 20
wifibroadcast cli -s .wireless.width 20
wifibroadcast cli -s .wireless.mlink 3994
wifibroadcast cli -s .wireless.wlan_adapter bl-r8812af1
wifibroadcast cli -s .wireless.link_control alink
wifibroadcast cli -s .broadcast.mcs_index 2
wifibroadcast cli -s .broadcast.tun_index 1
wifibroadcast cli -s .broadcast.fec_k 8
wifibroadcast cli -s .broadcast.fec_n 12
wifibroadcast cli -s .broadcast.stbc 1
wifibroadcast cli -s .broadcast.ldpc 1
wifibroadcast cli -s .broadcast.link_id 7669206

# wifibroadcast normally performs generic video setup on first start. Mark it
# initialized only after applying the device-specific values above so it will
# not replace 1280x720/H.265/6144 with its generic IMX335 profile.
touch /etc/system.ok

# Keep adaptive-link enabled as in the previously working FPV image.
sed -i '/alink_drone &/d' /etc/rc.local
sed -i -e '$i alink_drone &' /etc/rc.local

exit 0
