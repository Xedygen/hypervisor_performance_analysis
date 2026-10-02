# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline, owner* Write-up: Pi 5 setup, results and discussion are drafted; still open are the title,
   authors, abstract, checking the Pi 4 column against the thesis, the final figure set, and acknowledgments.
2. [ ] *needs Pi* Root-cell colouring kernel (`patches/linux-rpi-6.6-jailhouse-colours.patch`) works with
   `jailhouse_colours=24-31 cma=16M` (2026-10-02, tryboot `jh66/cmdline-col.txt`; 64 MB uncoloured pool for
   high-order allocations, 176 MB reserved, MemTotal 564 MB). Short S3 check (`results/pi5-colourkernel/`,
   1 run x 60 s, coloured guest, no colorhog) beats colorhog: `cache` 315 L3 refills/period and 191 us
   task (colorhog 469 / 232 us), `stream` 489 (790), `vm` 580 (726). With the default 64 MB CMA area it
   was much weaker (868 under `cache`): CMA hands guest colours to user pages. Next: make it the default
   cmdline and rerun S1/S3 (+S2) as a new "colkern" config, then update the write-up.
3. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
4. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
5. [ ] *owner decision* CPU hotplug is broken in firmware: on 2026-10-02 every secondary core (1-3) failed to
   come back online after 5-60 s offline ("CPU3: failed in unknown state : 0x0", then -22), also with the
   fully stock setup (kernel_2712, 16 KB pages, original cmdline). Not Jailhouse, not our kernel, not the
   offline time. Bootloader 2026-01-21 (`version ab8a9dde`), `rpi-eeprom-update` offers a newer one: try
   it and re-test. Until then bare-Linux reference runs boot with `maxcpus=3` instead of offlining CPU 3.
