# Pi 5 Jailhouse port: status and notes

Board: Raspberry Pi 5, 1 GB, Rev 1.1 (BCM2712 D0). Guest: Zephyr RTOS (bare-metal `rt-bench` until it runs).
Remaining work: [TODO.md](TODO.md).

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
- Active Cooler: full speed (PWM 255, ~9360 rpm) from 20 C since 2026-10-02 (trip points 20/30/40/50 C,
  all 255; backup `config.txt.bak-fan`). Campaigns up to E4 and the first Linux-guest run used the earlier
  temperature-controlled setting (40/50/57/63 C -> 100/150/200/255). Thermal guard service kills load at 75 C.
- Serial console: USB-TTL on GPIO14/15 (RP1 UART0, `ttyAMA0`, 115200 8N1); kernel log level 8 on it
  (`/etc/sysctl.d/99-serial-debug.conf`, `loglevel=8` in `jh66/cmdline.txt`). Output starts 0.41 s into
  boot and replays the log from 0 s. Host side: PuTTY on `/dev/ttyUSB0`, logging to `~/rpi5-serial.log`.
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

MemGuard fix verified on the board 2026-10-02. PREEMPT_RT Linux guest (`linux-guest/`, cells
`rpi5-linux-demo`/`rpi5-linux-col`) boots and runs cyclictest (idle: min 1, avg 2, max 5-15 us);
`experiments/pi_guest.sh` (GUEST=linux or zephyr) runs S1/S3 with it. Zephyr guest boots too (2026-10-02): `hello_world` and
`zephyr/rt-bench` (idle: wake-up latency avg 0.89 us, max 2.1 us, scheduler included; control task avg
~20 us, the same as bare-metal rt-bench under the default `ondemand` governor (20.0 us); the 13.9 us
reference is from the 2.4 GHz campaign). SD card retry not yet tested.

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
- **MemGuard (E4, 2026-10-02, fixed 2.4 GHz)**: works since the PPI 26 fix, no hangs in 24 runs.
  Budget 1000 L2 refills/core/ms with the guest+root colour partition: deadline misses under `cache`
  89 % -> 0.6 %, `stream` 100 % -> 0 %, `vm` 92 % -> 2.8 % (`figures/e4_memguard`). Spatial isolation
  alone at 1000: `cache` 5.4 %, `vm` 36 %, `stream` 84 %. Cost: the root's `cache` stressor drops to
  ~8 % of its throughput at 1000 (79 % at 20000).
- **Linux guest with cyclictest (2026-10-02, fixed 2.4 GHz, `results/pi5-linux/`)**: 1 kHz, priority 95,
  S1 300 s + S3 60 s per load, 1 run each. No sample above 100 us in any config. Idle max 11-18 us;
  root load raises the max to 63 us (`cache`), 54 us (`stream`), 79 us (`vm`) with spatial isolation
  only; with the guest+root colour partition 41/51/64 us. cyclictest's own working set is tiny, so
  cache interference shows only in the tail, unlike the rt-bench control task.
- Thermal: max 57.9 C, never throttled.

## Fixes waiting for a board test (2026-09-29)

- **MemGuard hang (E4)**: E4 ran right after E3 destroyed the 2+2 cell, so CPU 2 came back to Linux, whose
  `gic_cpu_init` cleared all PPI enables, including the EL2 timer (PPI 26) that refills the budget. The PMU
  count then only grew until it overflowed (~25 s at 20000) and CPU 2 blocked forever. PPI 26 is now
  removed from every cell's IRQ bitmap; the throttle loop no longer unmasks FIQ at EL2 (no FIQ vector);
  `memguard_exit` gives all PMU counters back to EL1.
- **Zephyr guest**: `zephyr/rpi5-jailhouse.overlay` + `.conf` on upstream `rpi_5`: RAM identity-mapped at
  0x30000000 (8 MB), GIC only (Jailhouse emulates GICD, maps GICV at the GICC address), console through
  Zephyr's `CONFIG_JAILHOUSE_DEBUG_CONSOLE` hypercall. `zephyr/rt-bench` is rt-bench as a cooperative
  Zephyr thread released by a `k_timer`; the expiry callback reads `CNTV_CVAL_EL0` (the deadline that
  fired), so `lat` covers the timer IRQ plus the Zephyr scheduler, like cyclictest. Same `W` line.
- **SD card kit**: apt runs from cloud-init `runcmd` and retries until the mirrors answer
  (log `/var/log/firstboot-apt.log`); the `packages` module had run before the network was up.

## Root-cell colouring (design, 2026-09-30)

jailhouse-rt cannot colour the root cell: `hypervisor/setup.c` maps the root memory regions 1:1, and
colouring works by mapping scattered physical fragments to contiguous cell addresses, which is impossible
under an already running Linux (late launch). So the root side must be excluded by Linux itself at boot.

- Colours repeat every 128 KB (32 colours x 4 KB). Keeping colours 24-31 away from Linux means reserving
  32 KB of every 128 KB: 6144 ranges over the 768 MB root RAM, 192 MB in total (colorhog pins ~120 MB).
- arm64 6.6 holds 1024 early memblock memory regions (`INIT_MEMBLOCK_REGIONS * 8`) and 128+NR_CPUS+1
  reserved ones, `/reserved-memory` only 64 (`MAX_RESERVED_REGIONS`), and arm64 has no `memmap=`.
  A DT or command-line list therefore does not fit.
- Implemented in `patches/linux-rpi-6.6-jailhouse-colours.patch`: early param
  `jailhouse_colours=<first>-<last>`; in `mem_init()` (first try in `bootmem_init()` hung the boot), after `paging_init()`
  (which calls `memblock_allow_resize()`, `arch/arm64/mm/mmu.c`) and before memblock hands pages to the
  buddy allocator, `memblock_reserve()` every guest-colour range inside the root RAM. The reserved
  array then grows as needed. Pages stay in the linear map but are never allocated. It runs after the CMA
  reservation (CMA needs contiguous memory), so the kernel image, early page tables and the CMA area still
  touch the guest colours; shrink `cma=` if that shows up in the L3 refills.
- DMA and the page cache follow automatically; nothing changes in Jailhouse. colorhog becomes unnecessary,
  and the guest configs keep their colours. Validate with `/proc/iomem`, `MemTotal` (~576 MB), and
  L3 refills of the coloured guest under `cache` load (colorhog numbers as the baseline).

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

- Kernel: `patches/linux-rpi-6.6-jailhouse-colours.patch` (root-cell colour reservation, see above) and
  `patches/linux-rpi-6.6-jailhouse-exports.patch` (apply to raspberrypi/linux `rpi-6.6.y` at 6.6.78):
  export `ioremap_page_range`, `__get_vm_area_caller`,
  `__hyp_stub_vectors`; new `ioremap_page_range_exec()` (plain `ioremap_page_range` forces NX, which
  crashed the first `enable` with an instruction abort in the hypervisor entry).
- jailhouse-rt: tracked in `jailhouse-rt/` (imported unmodified from v0.12 in its own commit, so
  `git log -p -- jailhouse-rt` shows the port): driver API fixes (sysfs groups, overlay call, vm_area),
  Kbuild `always` → `always-y`, stdarg shims, QoS no-platform fallback, MemGuard BCM2712 section
  (`CONFIG_MACH_RPI5`: PMU IRQs 48–51, EL2 timer IRQ 26; IRQ table bound 320 not verified),
  `configs/arm64/rpi5.c` and `rpi5-inmate-demo.c`.
- Zephyr: `zephyr/` (overlay + Kconfig fragment on upstream `rpi_5`, `rt-bench` app), cell
  `configs/arm64/rpi5-zephyr.c`, build with `scripts/build_zephyr.sh`.
- Local only, not in this repo: `raspberrypi-linux/` (own git, branch `jailhouse-6.6`, uncommitted),
  `build/` and `third_party/` (includes the Zephyr clone and its Python venv).
- SD card: `sdcard/flash_sd.sh` fills the password hash and SSH key into `sdcard/firstboot/user-data`
  at flash time; the password stays in `sdcard/firstboot/.pi-password` (not in the repo).
