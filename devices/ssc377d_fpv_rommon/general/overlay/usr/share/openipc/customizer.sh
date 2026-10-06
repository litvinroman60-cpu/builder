#!/bin/sh
#
# SSC377D FPV first-boot configuration
#
# Dedicated FPV image for PixelPilot + WFB-NG + RTL8812EU.
# Keep the camera side minimal: one video encoder, WFB video/tunnel/telemetry,
# and MSPOSD. Do not add surveillance streams/services here.
#

fw_setenv upgrade 'https://github.com/OpenIPC/builder/releases/download/latest/ssc377d_fpv.tgz'

# ---------------------------------------------------------------------------
# Camera / video
# ---------------------------------------------------------------------------
cli -s .video0.enabled true
cli -s .video0.size 1280x720
cli -s .video0.fps 60
cli -s .video0.bitrate 6144
cli -s .video0.codec h264
cli -s .video0.rcMode cbr
cli -s .fpv.enabled true
cli -s .fpv.noiseLevel 0
cli -s .video0.noiseLevel 0

# Stock SSC377D + IMX335 ISP path. Do not force a Greg/SSC338Q profile.
cli -s .isp.sensorConfig /etc/sensors/imx335.bin
# Do not force .isp.exposure here. The current SigmaStar FPV path uses the
# exposure value as the frame-rate ceiling and should be allowed to manage it.

# Only the main encoder is needed by PixelPilot.
cli -s .video1.enabled false
cli -s .jpeg.enabled false
cli -s .audio.enabled false
cli -s .records.enabled false
cli -s .rtsp.enabled false
cli -s .hls.enabled false
cli -s .motionDetect.enabled false
cli -s .osd.enabled false
cli -s .outgoing.enabled true
cli -s .outgoing.wfb true
cli -s .system.logLevel info
cli -s .watchdog.enabled true

# ---------------------------------------------------------------------------
# WFB-NG
# ---------------------------------------------------------------------------
wifibroadcast cli -s .wireless.channel 161
wifibroadcast cli -s .wireless.width 20
wifibroadcast cli -s .wireless.mlink 3994
wifibroadcast cli -s .wireless.link_control alink

# RTL8812EU / BL-M8812EU2 is the only Wi-Fi driver shipped in this image.
# OpenIPC's wifibroadcast service detects USB VID:PID 0bda:a81a and loads
# module 8812eu from the rtl88x2eu-openipc package.
if lsusb | grep -q '0bda:a81a'; then
    wifibroadcast cli -s .wireless.txpower 40
    wifibroadcast cli -s .wireless.wlan_adapter bl-m8812eu2
else
    echo "WARNING: RTL8812EU (0bda:a81a) not detected"
fi

wifibroadcast cli -s .broadcast.mcs_index 2
wifibroadcast cli -s .broadcast.tun_index 1
wifibroadcast cli -s .broadcast.fec_k 8
wifibroadcast cli -s .broadcast.fec_n 12
wifibroadcast cli -s .broadcast.stbc 1
wifibroadcast cli -s .broadcast.ldpc 1
wifibroadcast cli -s .broadcast.link_id 7669206

# Let the standard OpenIPC wifibroadcast service keep ownership of driver
# loading and the three required FPV paths:
#   1) video broadcast
#   2) bidirectional WFB tunnel
#   3) telemetry/MSPOSD
# Mark first-boot video setup complete only after our FPV values are written.
touch /etc/system.ok

# Adaptive Link is part of the intended FPV radio path.
sed -i '/alink_drone &/d' /etc/rc.local
sed -i -e '$i alink_drone &' /etc/rc.local

exit 0
