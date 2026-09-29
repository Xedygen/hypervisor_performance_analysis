# Pi 5 Jailhouse port — status and TODO

Last updated 2026-09-29. Board is powered off; steps below are tagged *offline* or *needs Pi*.
Board: Raspberry Pi 5, 1 GB, Rev 1.1 (BCM2712 D0). Guest plan: Zephyr RTOS.

## Where it stands

Working (2026-09-25):
- Pi OS Lite (Trixie) on SD, reachable at `ssh -i ~/.ssh/id_ed25519_rpi5 pi@rpi5.local` (10.42.0.150).
  Host shares Wi-Fi over `enp5s0` (NM connection `rpi5-share`).
- Custom root-cell kernel `6.6.78-v8-jailhouse+` (4K pages) is the default boot kernel.
- **jailhouse-rt runs end to end on the Pi 5**: `enable`, `cell create/load/start/destroy`, `disable`,
  CPU hotplug. Guest cells run on CPU 3 and print through the virtual console (no UART needed).
- Cache colouring: the hypervisor probes the L3 (2 MB, 16-way, 32 colours); coloured guest config
  `rpi5-rtbench-col.c` (8/32 colours).
- Thesis experiments (S1-S4 + follow-ups) run unattended (`experiments/pi_night.sh`, `pi_extra.sh`,
  `pi_fixed.sh`; `resume.sh` restarted them after resets from cron @reboot, since removed); results in `results/`,
  including the raw `console.log`/`markers.log` per config, so `experiments/analyze.py` can rebuild every table.
- Active Cooler: temperature-controlled with early trip points (40/50/57/63 C -> 100/150/200/255 PWM,
  Pi OS default is 50/60/67.5/75 C). Thermal guard service kills load at 75 C.
- systemd hardware watchdog (1 min) auto-reboots the Pi after a hang.

Pi 5 bugs found and fixed:
- **Stale SGI after `enable`** (jailhouse-rt): Linux enables the hypervisor from an IPI handler, so the
  physical SGI stays active; SGI 1 is Jailhouse's management event, so CPUs could never be suspended or
  woken again (CPU hotplug failed, `cell create` hung the board). Fix ported from upstream Jailhouse:
  deactivate active SGIs in `gicv2_cpu_init`.
- **`FPEXC32_EL2` on Cortex-A76** (upstream Jailhouse): the register is UNDEFINED when EL1 has no
  AArch32, so `arm_cpu_reset` faulted at EL2 when parking a CPU. Fixed in `patches/siemens-jailhouse-rpi5.patch`
  (jailhouse-rt does not touch the register).
- `ioremap_page_range` forces NX in 6.x; kernel patch adds `ioremap_page_range_exec`.

## Results so far (2026-09-25)

Two unattended campaigns, same runs: `results/pi5/` (default `ondemand` governor) and
`results/pi5-fixed/` (pinned at 2.4 GHz). Summaries in each `summary.md`, figures in `figures/`,
side-by-side in `results/figures-compare/`. The guest is the bare-metal `rt-bench` (1 kHz timer,
pointer-chase control task, 100 us deadline); all numbers below are the fixed-frequency campaign.

- Hypervisor latency is tiny: wake-up latency avg 0.30 us, worst 2.1 us idle, never above 44 us under load.
- **Spatial isolation alone fails under memory load**: `cache`/`stream`/`vm` on the root cores slow the
  guest task from 14 us to 380-480 us, with 96-100 % deadline misses; L3 refills go from ~8 to ~1000 per period.
- **Colouring only the guest (the Pi 4 thesis config) has no effect**: root Linux still uses the guest colours.
- **Guest + root partitioned (colorhog)** roughly halves L3 misses under `cache` (875 -> 469) and task time
  (379 -> 232 us), but most periods still miss the deadline.
- Follow-ups: the L3 behaves inclusively (a 256 KB set that fits the private L2 is still hit); colouring
  protects it well (3.9 % misses); more colours help; fewer noisy cores (2+2) help; `stream` (DRAM bandwidth)
  is not fixed by colouring - needs memory-bandwidth regulation.
- S2 (100 stressors): 27.1 % -> 25.0 % response-deadline misses (default frequency: 29.8 % -> 26.7 %).
- S4 UnixBench overhead of the root cell: 3.3 % (1 copy) / 3.7 % (3 copies) at 2.4 GHz
  (default frequency: 2.7 % / 1.4 %). Costliest: pipe-based context switching.
- Frequency pinning changes little: the conclusions hold in both campaigns.
- Board hangs (watchdog reset, run skipped as "hang"): default campaign `pipe`, `pipeherd`,
  `tlb-shootdown` (all with colorhog) and `vm` (8/32 colours + colorhog); fixed campaign `opcode`
  (spatial only), `vm` (16/32 + colorhog), `vm` (2+2 split, no colorhog). Most involve colorhog pinning
  memory on the 1 GB board, but two did not, and none reproduced reliably - root cause unknown.
- MemGuard (E4, budget 20000) hung the board right after `cell memguard` succeeded: the guest kept printing
  for ~25 s, but root Linux never wrote the next marker (a `sync`), i.e. root CPUs were throttled and never
  released. Experiment made opt-in.
- Thermal: max 57.9 C, never throttled.

## Next steps

1. [ ] *offline* Write-up: add the Pi 5 numbers and figures, and describe
   `rt-bench` (bare-metal, replaces cyclictest) and `colorhog` (root side of the colour partition).
2. [ ] *needs Pi + USB-TTL* Debug the board hangs with a USB-TTL adapter (3.3 V) on the SoC debug UART (PL011 `0x107d001000`,
   3-pin JST connector), root-cell kernel log on it too: `opcode` and `vm` without colorhog are the
   interesting cases. Consider giving the watchdog to the hypervisor/critical cell instead of root Linux.
3. [ ] *needs Pi* MemGuard on BCM2712. Likely cause found and fixed 2026-09-29 (not yet run): E4 ran right
   after E3 destroyed the 2+2 cell, so CPU 2 came back to Linux, whose `gic_cpu_init` cleared all PPI
   enables, including the EL2 timer (PPI 26) that refills the budget. The PMU count then only grew until
   it overflowed (~25 s at 20000) and CPU 2 blocked forever. PPI 26 is now hypervisor-only; the throttle
   loop also no longer unmasks FIQ at EL2 (no FIQ vector). Test in this order:
   a. `jailhouse cell memguard 0 1000 0` (timer only, never blocks), then `... 0 0 0`: board stays up.
   b. Destroy and re-create the rt-bench cell (CPU 3 goes through Linux), then `... 0 1000 20000`.
   c. Full E4: `MEMGUARD=1 experiments/pi_extra.sh` (needed for the `stream`/DRAM case).
4. [ ] *needs Pi* Repeat S2 three times per config (thesis used >= 3 full cycles; each campaign did 1 per config).
5. [ ] *offline build, Pi to run* Zephyr guest: board overlay based on Zephyr's `rpi_5` with RAM at the cell's base, GIC-400 at
   `0x107fff9000`/`0x107fffa000`, plus a console driver using the Jailhouse debug-putc hypercall
   (`hvc #0x4a48`, x0 = 8, x1 = char).
6. [ ] *offline design* Proper root-cell colouring instead of colorhog (jailhouse-rt can colour the root cell; needs more
   RAM than 1 GB leaves).
7. [ ] *flash to verify* SD card kit: cloud-init's package install partly failed on first boot (git,
   stress-ng, rt-tests, linux-perf, python3-mako, tmux were missing). Fixed 2026-09-29: apt now runs from
   `runcmd` and retries until the mirrors answer (log `/var/log/firstboot-apt.log`); confirm on a fresh flash.
8. [ ] *needs Pi* CPU 3 does not come back online after a long offline period without Jailhouse (firmware PSCI
   CPU_ON fails); bare-Linux reference runs therefore go last or should boot with `maxcpus=3`.

## How to rebuild and redeploy

```bash
# kernel (branch jailhouse-6.6 in raspberrypi-linux/, output in build/kernel-6.6)
cd raspberrypi-linux && make O=../build/kernel-6.6 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j16 Image modules dtbs
cd .. && scripts/install_kernel.sh      # installs to /boot/firmware/jh66/, keeps jh66/cmdline.txt, tryboots
# jailhouse-rt
cd jailhouse-rt && make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KDIR=../build/kernel-6.6 -j16
rsync -a --checksum -e "ssh -i ~/.ssh/id_ed25519_rpi5" ./ pi@rpi5.local:jailhouse-rt/ && ssh ... sync
# on the Pi
sudo cp hypervisor/jailhouse.bin /lib/firmware/ && sudo insmod driver/jailhouse.ko
sudo ./tools/jailhouse enable configs/arm64/rpi5.cell
```

- Always `sync` on the Pi after copying files. A hang loses unsynced writes (a `.cell` file got truncated once).
- Netconsole for Linux crashes: host `nc -klu 6666`, Pi `sudo modprobe netconsole netconsole=@/eth0,6666@10.42.0.1/`.
- After a host reboot, Docker blocks the Wi-Fi sharing again:
  `sudo iptables -I DOCKER-USER -i enp5s0 -j ACCEPT` and
  `sudo iptables -I DOCKER-USER -o enp5s0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT`.

## Pi boot config (for reference / rollback)

- `/boot/firmware/config.txt`: `kernel=kernel8.img`, `enable_uart=1`, fan params, `os_prefix=jh66/`
  (delete the `os_prefix` line to go back to the stock 6.18 kernel).
- `/boot/firmware/jh66/cmdline.txt`: `... id_aa64mmfr1.vh=0 kvm-arm.mode=none mem=768M`
  (backup `cmdline.txt.orig`). Stock `/boot/firmware/cmdline.txt` has the first two only.
- Memory: Linux 0x0–0x2fffffff, cells 0x30000000–0x3ebfffff, hypervisor 0x3ec00000–0x3fbfffff (16 MB), VideoCore from 0x3fc00000.

## Kernel / jailhouse-rt changes

- Kernel: `patches/linux-rpi-6.6-jailhouse-exports.patch` (apply to raspberrypi/linux `rpi-6.6.y` at 6.6.78):
  export `ioremap_page_range`, `__get_vm_area_caller`,
  `__hyp_stub_vectors`; new `ioremap_page_range_exec()` (plain `ioremap_page_range` forces NX, which
  crashed the first `enable` with an instruction abort in the hypervisor entry).
- jailhouse-rt: tracked in `jailhouse-rt/` (imported unmodified from v0.12 in its own commit, so
  `git log -p -- jailhouse-rt` shows the port): driver API fixes (sysfs groups, overlay call, vm_area),
  Kbuild `always` → `always-y`, stdarg shims, QoS no-platform fallback, MemGuard BCM2712 section
  (`CONFIG_MACH_RPI5`: PMU IRQs 48–51, EL2 timer IRQ 26; IRQ table bound 320 not verified),
  `configs/arm64/rpi5.c` and `rpi5-inmate-demo.c`.
- Local only, not in this repo: `raspberrypi-linux/` (own git, branch `jailhouse-6.6`, uncommitted),
  `build/` and `third_party/`.
- SD card: `sdcard/flash_sd.sh` fills the password hash and SSH key into `sdcard/firstboot/user-data`
  at flash time; the password stays in `sdcard/firstboot/.pi-password` (not in the repo).
