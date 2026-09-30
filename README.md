# Jailhouse cache colouring on Raspberry Pi 5

Port of a Jailhouse-based mixed-criticality setup (static partitioning + L2 cache colouring, from a
Raspberry Pi 4 MS thesis) to the Raspberry Pi 5 (BCM2712, Cortex-A76, shared L3). Guest: Zephyr RTOS.

Status and notes: [STATUS.md](STATUS.md). Open tasks: [TODO.md](TODO.md).

| Path | What |
|---|---|
| `jailhouse-rt/` | jailhouse-rt v0.12 (R. Mancuso, BU), ported to Linux 6.6 and the Pi 5. Imported unmodified first, so git history shows the port. |
| `patches/` | Patch for the Raspberry Pi `rpi-6.6.y` kernel that Jailhouse needs (symbol exports, executable ioremap). |
| `scripts/` | `setup_environment.sh` (host setup), `install_kernel.sh` (deploy the root-cell kernel to the Pi). |
| `sdcard/` | Flash Raspberry Pi OS Lite with cloud-init first-boot config (`sudo sdcard/flash_sd.sh /dev/sdX`). |
| `results/` | Measurement results per scenario (empty until experiments run). |

Not in the repo (local only): `raspberrypi-linux/` (kernel source, own git), `build/`, `third_party/`
(original zips, upstream Jailhouse) and the SD image.
