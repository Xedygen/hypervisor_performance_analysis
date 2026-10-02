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
4. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1).
5. [ ] *flash to verify* SD card kit: check `/var/log/firstboot-apt.log` and the package list on a fresh flash.
6. [ ] *needs Pi* CPU 3 does not come back online after a long offline period without Jailhouse (firmware
   PSCI CPU_ON fails); bare-Linux reference runs go last or boot with `maxcpus=3`.
