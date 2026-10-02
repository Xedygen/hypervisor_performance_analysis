# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline, owner* Write-up: Pi 5 setup, results and discussion are drafted; still open are the title,
   authors, abstract, checking the Pi 4 column against the thesis, the final figure set, and acknowledgments.
2. [ ] *needs Pi, ask the owner first* Root-cell colouring kernel (`patches/linux-rpi-6.6-jailhouse-colours.patch`):
   hangs at boot with `jailhouse_colours=24-31` (three tries 2026-10-02, power cycle each time). The serial
   log of the third (`~/rpi5-serial.log` on the host) shows the cause: a failed high-order allocation's
   memory dump with free blocks only of 32 and 64 KB (none >= 128 KB), then the console stops. The patch now
   keeps the first 64 MB uncoloured as a high-order pool (built, not booted). Next try: tryboot with
   `jh66/cmdline-col.txt` while logging the serial console.
3. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
4. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
5. [ ] *owner decision* CPU hotplug is broken in firmware: on 2026-10-02 every secondary core (1-3) failed to
   come back online after 5-60 s offline ("CPU3: failed in unknown state : 0x0", then -22), also with the
   fully stock setup (kernel_2712, 16 KB pages, original cmdline). Not Jailhouse, not our kernel, not the
   offline time. Bootloader 2026-01-21 (`version ab8a9dde`), `rpi-eeprom-update` offers a newer one: try
   it and re-test. Until then bare-Linux reference runs boot with `maxcpus=3` instead of offlining CPU 3.
