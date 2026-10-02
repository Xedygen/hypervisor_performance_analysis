# Jailhouse cache colouring on Raspberry Pi 5

Port of a Jailhouse-based mixed-criticality setup (static partitioning + L2 cache colouring, from a
Raspberry Pi 4 MS thesis) to the Raspberry Pi 5 (BCM2712, Cortex-A76, shared L3). The guest cell runs
a bare-metal benchmark (`rt-bench`), Zephyr RTOS, or PREEMPT_RT Linux with cyclictest.

Status and notes: [STATUS.md](STATUS.md). Open tasks: [TODO.md](TODO.md).

| Path | What |
|---|---|
| `jailhouse-rt/` | jailhouse-rt v0.12 (R. Mancuso, BU), ported to Linux 6.6 and the Pi 5 (incl. MemGuard on BCM2712). Imported unmodified first, so git history shows the port. Pi 5 cell configs: `configs/arm64/rpi5*.c`. |
| `patches/` | Patches for the Raspberry Pi `rpi-6.6.y` kernel: symbol exports and executable ioremap for Jailhouse; root-cell colour reservation (`jailhouse_colours=`, experimental). |
| `linux-guest/` | PREEMPT_RT Linux guest for cyclictest: kernel config, hypercall console driver, initramfs init, `build.sh`. |
| `zephyr/` | Zephyr guest: overlay + Kconfig fragment for the cell, `rt-bench` as a Zephyr app. Build with `scripts/build_zephyr.sh`. |
| `experiments/` | Campaign scripts run on the Pi (`pi_night.sh`, `pi_fixed.sh`, `pi_extra.sh`, `pi_guest.sh`, `pi_s2_repeat.sh`, shared `lib.sh`), `analyze.py` and `plots.py` on the host. |
| `scripts/` | Host setup, kernel install, Zephyr build, serial console logger (`serial_log.py`, user service) and live viewer. |
| `sdcard/` | Flash Raspberry Pi OS Lite with cloud-init first-boot config (`sudo sdcard/flash_sd.sh /dev/sdX`). |
| `results/` | Raw logs, per-run CSVs, summaries and figures per campaign (`pi5`, `pi5-fixed`, `pi5-linux`, `pi5-zephyr`). |

Not in the repo (local only): `raspberrypi-linux/` (kernel source, own git), `build/`, `third_party/`
(original zips, upstream Jailhouse, Zephyr, the guest kernel tree) and the SD image.
