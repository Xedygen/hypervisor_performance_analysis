# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline, owner* Write-up: Pi 5 setup, results and discussion are drafted; still open are the title,
   authors, abstract, checking the Pi 4 column against the thesis, the final figure set, and acknowledgments.
2. [ ] *needs Pi* Root-cell colouring kernel: `colkern` config in `results/pi5-fixed/` (tryboot with
   `jh66/cmdline-col.txt` = `jailhouse_colours=24-31 cma=16M`, S1 300 s + S3 1 run, 2026-10-02) beats colorhog
   on averages: `cache` 190 us / 76 % misses / 325 L3 refills (colorhog 232 / 89 % / 469), `stream` 213 us /
   468 (307 / 790), `vm` 338 us / 579 (375 / 726). But single-period maxima are higher (`memcpy` 641 us vs
   152, `pwalk` 545 vs 135, idle 215 vs 146): repeat S3 x3 to see if that tail is real, then S2.
3. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
4. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
5. [ ] *owner decision* CPU hotplug is broken in firmware: on 2026-10-02 every secondary core (1-3) failed to
   come back online after 5-60 s offline ("CPU3: failed in unknown state : 0x0", then -22), also with the
   fully stock setup (kernel_2712, 16 KB pages, original cmdline). Not Jailhouse, not our kernel, not the
   offline time. Bootloader 2026-01-21 (`version ab8a9dde`), `rpi-eeprom-update` offers a newer one: try
   it and re-test. Until then bare-Linux reference runs boot with `maxcpus=3` instead of offlining CPU 3.
