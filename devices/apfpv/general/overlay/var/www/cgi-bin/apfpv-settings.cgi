#!/bin/sh
# APFPV radio and MSP OSD settings page.
# Accept only enumerated/numeric values; never evaluate submitted data.

read_post() {
    [ "${REQUEST_METHOD:-GET}" = "POST" ] || return 0
    case "${CONTENT_LENGTH:-0}" in
        ''|*[!0-9]*) return 0 ;;
    esac
    [ "$CONTENT_LENGTH" -le 2048 ] || return 0
    POST_DATA=$(dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null)
}

field() {
    printf '%s\n' "$POST_DATA" | tr '&' '\012' | awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }'
}

valid_freq() {
    case "$1" in 5180|5200|5220|5240|5745|5765|5785|5805|5825) return 0 ;; *) return 1 ;; esac
}
valid_power() {
    case "$1" in 500|750|1000|1250|1500|1750|2000) return 0 ;; *) return 1 ;; esac
}
valid_port() {
    case "$1" in /dev/ttyS0|/dev/ttyS1|/dev/ttyS2) return 0 ;; *) return 1 ;; esac
}
valid_baud() {
    case "$1" in 9600|19200|38400|57600|115200) return 0 ;; *) return 1 ;; esac
}

freq=$(fw_printenv -n wlanfreq 2>/dev/null)
[ -n "$freq" ] || freq=5180
power=$(fw_printenv -n wlanpwr 2>/dev/null)
[ -n "$power" ] || power=1500
port=/dev/ttyS2
baud=115200
[ ! -r /etc/apfpv-msposd.conf ] || . /etc/apfpv-msposd.conf
port=${port:-/dev/ttyS2}
baud=${baud:-115200}
message=

read_post
if [ "${REQUEST_METHOD:-GET}" = "POST" ]; then
    action=$(field action)
    new_freq=$(field freq)
    new_power=$(field power)
    new_port=$(field port)
    new_baud=$(field baud)
    if [ "$action" = save ]; then
        if valid_freq "$new_freq" && valid_power "$new_power" && valid_port "$new_port" && valid_baud "$new_baud"; then
            if command -v fw_setenv >/dev/null 2>&1; then
                fw_setenv wlanfreq "$new_freq" && fw_setenv wlanpwr "$new_power"
                if [ "$?" -eq 0 ]; then
                    umask 077
                    printf 'port=%s\nbaud=%s\n' "$new_port" "$new_baud" > /etc/apfpv-msposd.conf
                    freq=$new_freq
                    power=$new_power
                    port=$new_port
                    baud=$new_baud
                    /etc/init.d/S99msposd stop >/dev/null 2>&1
                    sleep 1
                    /etc/init.d/S99msposd start >/dev/null 2>&1
                    message="Settings saved. MSPOSD restarted. Wi-Fi settings are saved; reboot the camera to apply the new frequency/power."
                else
                    message="ERROR: failed to save Wi-Fi environment settings."
                fi
            else
                message="ERROR: fw_setenv is not available."
            fi
        else
            message="ERROR: invalid value. Choose one of the listed frequencies, power levels, UARTs and baud rates."
        fi
    fi
fi

cat <<EOF
Content-type: text/html; charset=UTF-8
Cache-Control: no-store
Pragma: no-cache

<!doctype html>
<html lang="en" data-bs-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>APFPV Settings</title>
<link rel="stylesheet" href="/a/bootstrap.min.css">
<link rel="stylesheet" href="/a/bootstrap.override.css">
<script src="/a/bootstrap.bundle.min.js"></script>
</head>
<body class="apfpv">
<nav class="navbar navbar-expand-lg bg-body-tertiary"><div class="container">
<a class="navbar-brand" href="status.cgi">OpenIPC APFPV</a>
<a class="nav-link" href="status.cgi">Status</a>
</div></nav>
<main class="container py-4">
<h2>APFPV Radio &amp; Telemetry</h2>
EOF
if [ -n "$message" ]; then
    case "$message" in ERROR*) printf '<div class="alert alert-danger">%s</div>\n' "$message" ;; *) printf '<div class="alert alert-success">%s</div>\n' "$message" ;; esac
fi
cat <<EOF
<div class="alert alert-warning">Radio changes are restricted to the listed 5 GHz frequencies and up to 20 dBm. Actual legal limits depend on your country, antenna gain and adapter. Saving does not guarantee the driver accepts every setting.</div>
<form method="post" action="apfpv-settings.cgi" class="card card-body mb-4">
<input type="hidden" name="action" value="save">
<h4>Wi-Fi access point</h4>
<div class="mb-3"><label class="form-label" for="freq">Frequency</label>
<select class="form-select" id="freq" name="freq">
EOF
for f in 5180 5200 5220 5240 5745 5765 5785 5805 5825; do
  if [ "$f" = "$freq" ]; then sel=selected; else sel=; fi
  printf '<option value="%s" %s>%s MHz (channel %s)</option>\n' "$f" "$sel" "$f" "$(( (f - 5000) / 5 ))"
done
cat <<EOF
</select><div class="form-text">5 GHz only. Some channels may be unavailable due to regulatory domain or adapter/driver support.</div></div>
<div class="mb-3"><label class="form-label" for="power">Transmit power</label>
<select class="form-select" id="power" name="power">
EOF
for p in 500 750 1000 1250 1500 1750 2000; do
  dbm=$((p / 100))
  if [ "$p" = "$power" ]; then sel=selected; else sel=; fi
  printf '<option value="%s" %s>%s mBm (~%s dBm)</option>\n' "$p" "$sel" "$p" "$dbm"
done
cat <<EOF
</select><div class="form-text">Driver value is mBm. Maximum exposed here is 2000 mBm (20 dBm).</div></div>
<hr><h4>Flight-controller OSD (MSP DisplayPort)</h4>
<div class="alert alert-warning">The available /dev/ttyS0–2 devices do not tell us which UART is physically free. Pytti and IR-cut wiring may already use a port. Select a port only after checking the board pinout; saving restarts msposd on that port.</div>
<div class="mb-3"><label class="form-label" for="port">UART device</label><select class="form-select" id="port" name="port">
EOF
for p in /dev/ttyS0 /dev/ttyS1 /dev/ttyS2; do
  if [ "$p" = "$port" ]; then sel=selected; else sel=; fi
  printf '<option value="%s" %s>%s</option>\n' "$p" "$sel" "$p"
done
cat <<EOF
</select></div>
<div class="mb-3"><label class="form-label" for="baud">UART baud rate</label><select class="form-select" id="baud" name="baud">
EOF
for b in 9600 19200 38400 57600 115200; do
  if [ "$b" = "$baud" ]; then sel=selected; else sel=; fi
  printf '<option value="%s" %s>%s</option>\n' "$b" "$sel" "$b"
done
cat <<EOF
</select><div class="form-text">For MSP DisplayPort, 115200 is a common setting, but the flight controller must use the same baud and MSP DisplayPort protocol.</div></div>
<button class="btn btn-primary" type="submit">Save settings</button>
</form>
<h4>Detected serial devices</h4><pre>
EOF
ls -l /dev/ttyS* 2>&1
cat <<EOF
</pre>
<p class="text-secondary">A device node existing does not prove the UART is free or wired to D8. Check the camera board pinout before changing the port.</p>
</main></body></html>
EOF
