# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline, owner* Write-up: Pi 5 setup, results and discussion are drafted; still open are the title,
   authors, abstract, checking the Pi 4 column against the thesis, the final figure set, and acknowledgments.
2. [ ] *needs Pi* Linux guest: S2 (100 stressors) and E4 (MemGuard) with cyclictest; check which
   threshold the thesis used for its timeout rate and recount from the histogram if it is not 100 us.
3. [ ] *needs Pi* Zephyr guest (boots, rt-bench runs): find why the control task is ~20 us vs 13.9 us
   bare-metal, then add coloured Zephyr cells and a Zephyr campaign through `start_cell`.
4. [ ] *needs Pi + owner* Root-cell colouring: the patched kernel boots normally without the parameter
   (installed as jh66, 2026-10-02), but a tryboot with `jailhouse_colours=24-31 panic=10`
   (`jh66/cmdline-col.txt` via `cmdline=` in tryboot.txt) hung early and needed a power cycle. Likely an
   early contiguous memblock allocation (percpu first chunk, etc.) no longer fits between the 96 KB
   holes: get the boot log on the debug UART (with item 5), or reserve later / skip the top of RAM.
5. [ ] *needs Pi + USB-TTL* Debug the board hangs on the SoC debug UART (PL011 `0x107d001000`, 3-pin JST,
   3.3 V), root-cell kernel log on it too: `opcode` and `vm` without colorhog are the interesting cases.
   Consider giving the watchdog to the hypervisor/critical cell instead of root Linux.
6. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
7. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
8. [ ] *needs Pi* CPU 3 does not come back online after a long offline period without Jailhouse (firmware
   PSCI CPU_ON fails); bare-Linux reference runs go last or boot with `maxcpus=3`.
