# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline, owner* Write-up: Pi 5 setup, results and discussion are drafted; still open are the title,
   authors, abstract, checking the Pi 4 column against the thesis, the final figure set, and acknowledgments.
2. [ ] *needs Pi* Root-cell colouring kernel (`patches/linux-rpi-6.6-jailhouse-colours.patch`): with the 64 MB
   high-order pool it boots (2026-10-02, tryboot `jh66/cmdline-col.txt`): 176 MB reserved, MemTotal 567 MB.
   But it isolates much less than colorhog (`results/pi5-colourkernel/`, S3 1 run, coloured guest, no
   colorhog): `cache` 868 L3 refills/period (guest-only colouring 1026, colorhog 469), task 391 us (439/232).
   Likely cause: the uncoloured low RAM - the 64 MB pool plus the 64 MB CMA area at 28-92 MB, which movable
   user pages use - still gives guest colours to the stressors. Next: `cma=16M` and a smaller pool, or
   reserve the guest colours above the pool and CMA and let colorhog cover the rest.
3. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
4. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
5. [ ] *owner decision* CPU hotplug is broken in firmware: on 2026-10-02 every secondary core (1-3) failed to
   come back online after 5-60 s offline ("CPU3: failed in unknown state : 0x0", then -22), also with the
   fully stock setup (kernel_2712, 16 KB pages, original cmdline). Not Jailhouse, not our kernel, not the
   offline time. Bootloader 2026-01-21 (`version ab8a9dde`), `rpi-eeprom-update` offers a newer one: try
   it and re-test. Until then bare-Linux reference runs boot with `maxcpus=3` instead of offlining CPU 3.
