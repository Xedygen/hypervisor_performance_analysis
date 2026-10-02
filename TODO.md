# TODO

Open tasks only; state, results and notes are in [STATUS.md](STATUS.md). The Pi is powered off:
tasks are tagged *offline* or *needs Pi*.

1. [ ] *offline, owner* Write-up: Pi 5 setup, results and discussion are drafted; still open are the title,
   authors, abstract, checking the Pi 4 column against the thesis, the final figure set, and acknowledgments.
2. [ ] *running 2026-10-02* Linux guest S2 + E4 (`GUEST=linux FULL=1 experiments/pi_guest.sh ~/results-linux`);
   then compare S2 with the Pi 4 thesis (same 100 us threshold: 19 % of cyclictest samples overall,
   `cache` alone 99 %; Pi 5 S3 `cache` is 0 %, max 63 us). Zephyr S2/E4 could follow with `GUEST=zephyr FULL=1`.
3. [ ] *needs Pi, ask the owner first* Root-cell colouring kernel (`patches/linux-rpi-6.6-jailhouse-colours.patch`):
   hangs at boot with `jailhouse_colours=24-31` (three tries 2026-10-02, power cycle each time). The serial
   log of the third (`~/rpi5-serial.log` on the host) shows the cause: a failed high-order allocation's
   memory dump with free blocks only of 32 and 64 KB (none >= 128 KB), then the console stops. The patch now
   keeps the first 64 MB uncoloured as a high-order pool (built, not booted). Next try: tryboot with
   `jh66/cmdline-col.txt` while logging the serial console.
4. [ ] *needs Pi* Debug the board hangs (`opcode`, `vm` without colorhog are the interesting cases): the
   serial console (USB-TTL on GPIO14/15, kernel log level 8) is now logged all the time to
   `~/rpi5-serial.log` on the host, so the next hang during a campaign leaves its last kernel messages
   there. If it shows nothing, try the 3-pin debug UART (needs a JST cable). Consider giving the watchdog
   to the hypervisor/critical cell instead of root Linux.
   Clue (2026-10-02, serial log): Linux-guest S2 with colorhog (128 MB pinned of 768 MB) hit the OOM killer
   under `memrate` (3 kills in 4 s, one triggered by the thermal guard's own allocation). Several earlier
   hangs were colorhog runs: memory exhaustion in the root cell is a candidate cause. Test: re-run the
   hang stressors with colorhog keeping more memory free, or watch `/proc/meminfo` during them.
   Hang caught 2026-10-02 15:0x (Linux-guest S2, colhog, stressor 58/100, uptime 3884 s), serial log:
   `rcu_preempt kthread timer wakeup didn't happen for 5255 jiffies ... Possible timer handling issue on
   cpu=2`, CPU 2 idle in swapper; the kernel still printed 147 s later, then the watchdog reset it. A root
   CPU lost its timer interrupt. First suspect, the per-CPU pending-IRQ queue dropping IRQs when full,
   is fixed (coalescing commit) but NOT the cause: the same stall (`timer wakeup didn't happen ... cpu=2`,
   again CPU 2, under `stress-ng-stack`, ~30 s after `cell create` + colorhog) recurred on the fixed
   hypervisor at 15:16 without any queue-full warning, and recovered by itself. Always CPU 2 so far.
   Next: when it happens, dump `/proc/interrupts` (arch_timer count per CPU) and `jailhouse cell stats`,
   try `rcupdate.rcu_cpu_stall_ftrace_dump=1`, and check what is special about CPU 2 (MPIDR 0x200).
5. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
6. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
7. [ ] *needs Pi* CPU 3 does not come back online after a long offline period without Jailhouse (firmware
   PSCI CPU_ON fails); bare-Linux reference runs go last or boot with `maxcpus=3`.
