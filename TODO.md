# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline, owner* Write-up: Pi 5 setup, results and discussion are drafted; still open are the title,
   authors, abstract, checking the Pi 4 column against the thesis, the final figure set, and acknowledgments.
2. [ ] *needs Pi* Linux guest: S2 (100 stressors) and E4 (MemGuard) with cyclictest; check which
   threshold the thesis used for its timeout rate and recount from the histogram if it is not 100 us.
3. [ ] *needs Pi* Zephyr guest (boots, rt-bench runs): find why the control task is ~20 us vs 13.9 us
   bare-metal, then add coloured Zephyr cells and a Zephyr campaign through `start_cell`.
4. [ ] *needs Pi + USB-TTL* Root-cell colouring kernel (`patches/linux-rpi-6.6-jailhouse-colours.patch`):
   boots fine without the parameter, but hangs early with `jailhouse_colours=24-31` both when reserving
   in `bootmem_init()` and in `mem_init()` (2026-10-02, power cycle needed each time; `panic=10` never
   rebooted, so it is a hang, not a panic). Structural problem either way: with a 32 KB hole every
   128 KB the largest free block is 64 KB (order 4), so any order >= 5 allocation fails or retries forever.
   Get the boot log on the debug UART first (with item 5). Options: keep a high-order pool uncoloured
   (e.g. skip the first 64 MB), or drop this and keep colorhog. Parked until then.
5. [ ] *needs Pi + USB-TTL* Debug the board hangs on the SoC debug UART (PL011 `0x107d001000`, 3-pin JST,
   3.3 V), root-cell kernel log on it too: `opcode` and `vm` without colorhog are the interesting cases.
   Consider giving the watchdog to the hypervisor/critical cell instead of root Linux.
6. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
7. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
8. [ ] *needs Pi* CPU 3 does not come back online after a long offline period without Jailhouse (firmware
   PSCI CPU_ON fails); bare-Linux reference runs go last or boot with `maxcpus=3`.
