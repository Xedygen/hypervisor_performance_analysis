#!/usr/bin/env python3
"""Log the Pi 5 serial console (USB-TTL on GPIO14/15, 115200 8N1) to a file.

Usage: serial_log.py [device] [logfile]   (default /dev/ttyUSB0, ~/rpi5-serial.log)

Opens the port non-blocking and sets raw 115200 with CLOCAL itself: after the
adapter re-enumerates its settings reset, and a plain open() then waits for a
carrier forever. Reopens the port when it disappears (unplug, power cycle) and
writes a "=== ... ===" marker with the host time at every (re)open.
"""
import os
import sys
import termios
import time
from pathlib import Path

DEV = sys.argv[1] if len(sys.argv) > 1 else "/dev/ttyUSB0"
LOG = Path(sys.argv[2] if len(sys.argv) > 2 else Path.home() / "rpi5-serial.log")


def open_port():
    fd = os.open(DEV, os.O_RDONLY | os.O_NOCTTY | os.O_NONBLOCK)
    iflag, oflag, cflag, lflag, _, _, cc = termios.tcgetattr(fd)
    cflag = (cflag & ~(termios.PARENB | termios.CSTOPB | termios.CSIZE | termios.CRTSCTS)) \
        | termios.CS8 | termios.CLOCAL | termios.CREAD
    cc[termios.VMIN], cc[termios.VTIME] = 1, 0
    termios.tcsetattr(fd, termios.TCSANOW,
                      [0, 0, cflag, 0, termios.B115200, termios.B115200, cc])
    os.set_blocking(fd, True)
    return fd


def main():
    with LOG.open("ab", buffering=0) as log:
        while True:
            try:
                fd = open_port()
            except OSError:
                time.sleep(2)
                continue
            log.write(f"\n=== serial_log open {time.strftime('%F %T')} ===\n".encode())
            try:
                while data := os.read(fd, 4096):
                    log.write(data)
            except OSError:
                pass
            os.close(fd)
            time.sleep(1)


if __name__ == "__main__":
    main()
