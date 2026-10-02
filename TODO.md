# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline, owner* Write-up: Pi 5 setup, results and discussion are drafted; still open are the title,
   authors, abstract, checking the Pi 4 column against the thesis, the final figure set, and acknowledgments.
2. [ ] *needs Pi* Linux guest: S2 (100 stressors) and E4 (MemGuard) with cyclictest; check which
   threshold the thesis used for its timeout rate and recount from the histogram if it is not 100 us.
3. [ ] *needs Pi* Zephyr guest (boots, rt-bench runs): find why the control task is ~20 us vs 13.9 us
   bare-metal, then add coloured Zephyr cells and a Zephyr campaign through `start_cell`.
4. [ ] *needs Pi, ask the owner first* Root-cell colouring kernel (`patches/linux-rpi-6.6-jailhouse-colours.patch`):
   hangs at boot with `jailhouse_colours=24-31` (three tries 2026-10-02, power cycle each time). The serial
   log of the third (`~/rpi5-serial.log` on the host) shows the cause: a failed high-order allocation's
   memory dump with free blocks only of 32 and 64 KB (none >= 128 KB), then the console stops. The patch now
   keeps the first 64 MB uncoloured as a high-order pool (built, not booted). Next try: tryboot with
   `jh66/cmdline-col.txt` while logging the serial console.
5. [ ] *needs Pi + USB-TTL* Debug the board hangs on the SoC debug UART (PL011 `0x107d001000`, 3-pin JST,
   3.3 V), root-cell kernel log on it too: `opcode` and `vm` without colorhog are the interesting cases.
   Consider giving the watchdog to the hypervisor/critical cell instead of root Linux.
6. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
7. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
8. [ ] *needs Pi* CPU 3 does not come back online after a long offline period without Jailhouse (firmware
   PSCI CPU_ON fails); bare-Linux reference runs go last or boot with `maxcpus=3`.
