# Pi 5 Jailhouse port — status and TODO

Last updated 2026-09-24. Board: Raspberry Pi 5, 1 GB, Rev 1.1 (BCM2712 D0). Guest plan: Zephyr RTOS.

## Where it stands

Working:
- Pi OS Lite (Trixie) on SD, reachable at `ssh -i ~/.ssh/id_ed25519_rpi5 pi@rpi5.local` (10.42.0.150).
  Host shares Wi-Fi over `enp5s0` (NM connection `rpi5-share`).
- Custom root-cell kernel `6.6.78-v8-jailhouse+` (4K pages) is the default boot kernel.
- jailhouse-rt builds against it; driver loads; **`jailhouse enable configs/arm64/rpi5.cell` works**
  (all 4 CPUs, MemGuard init OK, cache probe picks L3: 2 MB, 16-way, 32 colours, way size 0x20000).
- Active Cooler forced to full speed permanently (`dtparam=fan_temp*` in `/boot/firmware/config.txt`).
- systemd hardware watchdog (1 min) auto-reboots the Pi after a hang. No power-cycling needed.

Blocked:
- **`jailhouse cell create configs/arm64/rpi5-inmate-demo.cell` hangs the whole board.**
  Linux offlines CPU 3 (`psci: CPU3 killed`), then everything freezes and the watchdog resets it.
  The hypervisor prints nothing before the hang (`jailhouse console -f` streamed live to the host
  showed no new lines), so it stops somewhere in `cell_create` while all root CPUs are suspended.
  RAM does not survive the watchdog reset (tested at 0x3fbff000), so the log can't be recovered.

## Next steps

1. [ ] **Get the hypervisor log from the hang. Needs the USB-TTL adapter (3.3 V only!).**
   - Easiest: set the root config `debug_console` to the SoC debug UART (PL011 `0x107d001000`,
     the 3-pin JST "UART" connector between the HDMI ports; needs a JST-SH to Dupont cable),
     `.type = JAILHOUSE_CON_TYPE_PL011`, flags `JAILHOUSE_CON_ACCESS_MMIO | JAILHOUSE_CON_REGDIST_4`.
   - Alternative: GPIO 14/15 = RP1 UART0 at `0x1f00030000` (PCIe BAR, only valid after Linux has set
     up RP1; also Linux's `ttyAMA0` console, so drop `console=serial0` from `jh66/cmdline.txt`).
   - Unfinished no-adapter idea: test whether RAM lower in the carve-out (0x30000000, 0x3ec00000)
     survives a watchdog reset. The script is on the Pi at `~/marker.py`
     (`sudo python3 marker.py write`, crash with sysrq `c`, after reboot `sudo python3 marker.py read`).
2. [ ] Suspects for the `cell create` hang, to check once there is a log:
   - jailhouse-rt colouring hooks in `cell_create` (`coloring_cell_init`, `hypervisor/arch/arm64/coloring.c`).
   - SGI delivery / CPU 3 park-reset path on Cortex-A76 (MPIDR Aff1 = core id, not Aff0).
   - MemGuard IRQ hooks (`memguard_handle_interrupt`, `memguard_block_if_needed`). Try with MemGuard
     disabled (stub out `memguard_init`) to rule it in or out.
   - Compare against upstream `third_party/siemens-jailhouse` (plain Jailhouse, no colouring/MemGuard):
     port the same 6.6 fixes there and try `cell create`. If it works, the bug is in jailhouse-rt's additions.
3. [ ] Run `gic-demo` in the cell; output should show up in `sudo jailhouse console -f`
   (cell config sets `JAILHOUSE_CELL_VIRTUAL_CONSOLE_ACTIVE`).
4. [ ] Coloured cell config: `jailhouse_memory_colored` regions for the guest, e.g. 8 of 32 L3 colours (25%, as in the Pi 4 thesis).
5. [ ] Zephyr guest: board overlay based on Zephyr's `rpi_5` with RAM at the cell's base, GIC-400 at
   `0x107fff9000`/`0x107fffa000`, plus a small console driver using the Jailhouse debug-putc hypercall
   (`hvc #0x4a48`, x0 = 8, x1 = char). Zephyr has no ARM64 Jailhouse console.
6. [ ] Experiments (thesis scenarios 1–4: cyclictest/stress-ng/UnixBench/perf) on the Pi 5.

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
- `raspberrypi-linux/` (own git, branch `jailhouse-6.6`, uncommitted), `build/`, `third_party/` are local only,
  not in this repo.
- SD card: `sdcard/flash_sd.sh` fills the password hash and SSH key into `sdcard/firstboot/user-data`
  at flash time; the password stays in `sdcard/firstboot/.pi-password` (not in the repo).
