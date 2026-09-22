#!/bin/sh
#
# SSC377D FPV first-boot configuration
#
# Keep the image aligned with the working PixelPilot/WFB setup. Do not force a
# Greg/SSC338Q ISP profile on SSC377D: the published Greg FPV VII profile is
# documented for Star6E/SSC338Q, while the known SSC377D+IMX335 reference path
# uses the stock imx335.bin profile.
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

# Use the stock OpenIPC IMX335 ISP profile. The SSC377D+IMX335 reference
# firmware loads /etc/sensors/imx335.bin. Do not set .isp.exposure here: the
# automatic exposure ceiling is tied to the requested FPS on current SigmaStar
# Majestic and should not be overridden during first boot.
cli -s .isp.sensorConfig /etc/sensors/imx335.bin

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
