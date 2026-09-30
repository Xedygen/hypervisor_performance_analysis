# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline* Write-up: add the Pi 5 numbers and figures, describe `rt-bench` (replaces cyclictest)
   and `colorhog` (root side of the colour partition).
2. [ ] *needs Pi* Test the MemGuard fix, in this order:
   a. `jailhouse cell memguard 0 1000 0` (timer only, never blocks), then `... 0 0 0`: board stays up.
   b. Destroy and re-create the rt-bench cell (CPU 3 goes through Linux), then `... 0 1000 20000`.
   c. Full E4: `MEMGUARD=1 experiments/pi_extra.sh` (needed for the `stream`/DRAM case).
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
