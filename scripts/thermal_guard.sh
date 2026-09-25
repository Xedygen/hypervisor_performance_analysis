#!/bin/bash
# Thermal guard for unattended experiments on the Pi 5.
# Logs temperature, fan speed and firmware throttle flags every 2 s to
# /var/log/thermal.csv. At LIMIT millidegrees or more it kills the load
# generators and creates /run/thermal-abort; experiment scripts check it.
# Install: scripts/thermal-guard.service (runs this as root).
LIMIT=${LIMIT:-75000}
LOG=/var/log/thermal.csv
FLAG=/run/thermal-abort
KILL_PATTERN='stress-ng|pwalk|UnixBench'

[ -f "$LOG" ] || echo "time,temp_mC,fan_rpm,fan_pwm,throttled" > "$LOG"
fan=$(ls -d /sys/devices/platform/cooling_fan/hwmon/hwmon* 2>/dev/null | head -1)

while true; do
  t=$(cat /sys/class/thermal/thermal_zone0/temp)
  rpm=$(cat "$fan/fan1_input" 2>/dev/null || echo -1)
  pwm=$(cat "$fan/pwm1" 2>/dev/null || echo -1)
  thr=$(vcgencmd get_throttled 2>/dev/null | cut -d= -f2)
  echo "$(date +%s),$t,$rpm,$pwm,$thr" >> "$LOG"
  if [ "$t" -ge "$LIMIT" ]; then
    echo "$(date +%s) temp $t >= $LIMIT, killing load" >> "$FLAG"
    pkill -9 -f -E "$KILL_PATTERN"
  fi
  sleep 2
done
