# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline, owner* Write-up: Pi 5 setup, results and discussion are drafted; still open are the title,
   authors, abstract, checking the Pi 4 column against the thesis, the final figure set, and acknowledgments.
2. [ ] *needs Pi* Linux guest: S2 (100 stressors) and E4 (MemGuard) with cyclictest; check which
   threshold the thesis used for its timeout rate and recount from the histogram if it is not 100 us.
3. [ ] *needs Pi* Run the Zephyr guest: `scripts/build_zephyr.sh third_party/zephyr/samples/hello_world`
   first, then `zephyr/rt-bench` with cell `rpi5-zephyr.cell`, loaded at `-a 0x30000000`.
   Afterwards add coloured variants of the cell and a `ZEPHYR=1` switch in `experiments/lib.sh start_cell`.
4. [ ] *needs Pi* Root-cell colouring: kernel built with `patches/linux-rpi-6.6-jailhouse-colours.patch`; install it,
   add `jailhouse_colours=24-31` to `jh66/cmdline.txt`, check `dmesg` (192 MB reserved) and `MemTotal`, then
   rerun S3/E1 with the coloured guest and no colorhog.
5. [ ] *needs Pi + USB-TTL* Debug the board hangs on the SoC debug UART (PL011 `0x107d001000`, 3-pin JST,
   3.3 V), root-cell kernel log on it too: `opcode` and `vm` without colorhog are the interesting cases.
   Consider giving the watchdog to the hypervisor/critical cell instead of root Linux.
6. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
7. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
8. [ ] *needs Pi* CPU 3 does not come back online after a long offline period without Jailhouse (firmware
   PSCI CPU_ON fails); bare-Linux reference runs go last or boot with `maxcpus=3`.
