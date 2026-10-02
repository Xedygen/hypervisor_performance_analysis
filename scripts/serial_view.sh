#!/usr/bin/env bash
# Follow the Pi 5 serial console live (read-only; scripts/serial_log.py, run by
# the rpi5-serial-log user service, owns the port and writes the log).
# Usage: serial_view.sh [lines of history, default 200] [logfile]
exec tail -n "${1:-200}" -F "${2:-$HOME/rpi5-serial.log}"
