#!/bin/sh
#
# SSC377D FPV: PixelPilot + WFB-NG.
# Test either RTL8812AU or RTL8812EU, with only one USB adapter attached
# during a boot. S97rtl88x2eu selects the matching WFB profile at each boot.
#

fw_setenv upgrade 'https://github.com/OpenIPC/builder/releases/download/latest/ssc377d_fpv.tgz'

# Camera / video: retain the known low-latency PixelPilot target.
cli -s .video0.enabled true
cli -s .video0.size 1280x720
cli -s .video0.fps 60
cli -s .video0.bitrate 6144
cli -s .video0.codec h264
cli -s .video0.rcMode cbr
cli -s .fpv.enabled true
cli -s .fpv.noiseLevel 0
cli -s .video0.noiseLevel 0

# Stock SSC377D + IMX335 ISP profile; don't inject Greg/SSC338Q binaries.
cli -s .isp.sensorConfig /etc/sensors/imx335.bin

# Use MSPOSD for Betaflight's MSP DisplayPort OSD. The WFB-NG telemetry
# router starts one msposd instance with -z (render at video resolution);
# don't start a second copy, which can contend for the UART/RGN.
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

# WFB-NG radio defaults shared by AU and EU adapters.
wifibroadcast cli -s .wireless.channel 161
wifibroadcast cli -s .wireless.width 20
wifibroadcast cli -s .wireless.mlink 3994
wifibroadcast cli -s .wireless.link_control alink

wifibroadcast cli -s .broadcast.mcs_index 2
wifibroadcast cli -s .broadcast.tun_index 1
wifibroadcast cli -s .broadcast.fec_k 8
wifibroadcast cli -s .broadcast.fec_n 12
wifibroadcast cli -s .broadcast.stbc 1
wifibroadcast cli -s .broadcast.ldpc 1
wifibroadcast cli -s .broadcast.link_id 7669206

# Mark setup complete only after all camera and WFB values are written.
touch /etc/system.ok

# Adaptive Link is part of the intended FPV radio path.
sed -i '/alink_drone &/d' /etc/rc.local
sed -i -e '$i alink_drone &' /etc/rc.local

exit 0
