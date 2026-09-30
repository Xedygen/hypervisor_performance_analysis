#!/usr/bin/env bash
# setup_environment.sh
# Phase 0 environment setup for the Jailhouse cache-coloring / Raspberry Pi 5 project.
# Run this ON YOUR UBUNTU HOST (not on the Pi itself), from anywhere:
#   bash setup_environment.sh
#
# What this does, matching the project guide Phase 0:
#   1. Installs the cross-toolchain + kernel-build prerequisites via apt (needs sudo).
#   2. Clones raspberrypi/linux (shallow, rpi-6.6.y) if it isn't already present here.
#   3. Unpacks upstream siemens-jailhouse (reference only) from third_party/.
#      The ported jailhouse-rt lives in jailhouse-rt/ in this repo.
#   4. Creates the results/ directory structure from the project guide §4.4, so
#      Pi 4 vs. Pi 5 runs land in matching folders from the start.
#
# Safe to re-run — every step checks whether its target already exists first.

set -uo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "==> Project directory: $PROJECT_DIR"

# ---------------------------------------------------------------------------
# 1. APT packages
# ---------------------------------------------------------------------------
echo
echo "==> Installing cross-toolchain and build prerequisites (needs sudo)..."
PACKAGES=(
  build-essential
  gcc-aarch64-linux-gnu
  g++-aarch64-linux-gnu
  git
  device-tree-compiler
  qemu-system-arm
  qemu-system-aarch64
  bc
  bison
  flex
  libssl-dev
  libncurses-dev
  rsync
  cpio
  unzip
  gdb-multiarch
  minicom          # serial console for the USB-UART adapter
  python3-pip
)

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y "${PACKAGES[@]}"
else
  echo "!! apt-get not found — this script targets Debian/Ubuntu. Install the"
  echo "   following packages manually with your distro's package manager:"
  printf '   - %s\n' "${PACKAGES[@]}"
fi

echo
echo "==> Verifying toolchain..."
for t in git aarch64-linux-gnu-gcc dtc qemu-system-aarch64 make; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "   [ok] $t -> $(command -v "$t")"
  else
    echo "   [MISSING] $t"
  fi
done

# ---------------------------------------------------------------------------
# 2. raspberrypi/linux (device-tree source + base of the patched root-cell
#    kernel, branch jailhouse-6.6; see install_kernel.sh and STATUS.md)
# ---------------------------------------------------------------------------
echo
if [ -d "$PROJECT_DIR/raspberrypi-linux/.git" ]; then
  echo "==> raspberrypi/linux already present at raspberrypi-linux/ — skipping clone."
else
  echo "==> Cloning raspberrypi/linux (branch rpi-6.6.y, shallow — this is a large"
  echo "    repo, expect it to take a while and use a few GB of disk)..."
  git clone --depth 1 -b rpi-6.6.y https://github.com/raspberrypi/linux.git \
    "$PROJECT_DIR/raspberrypi-linux" \
    || echo "!! Clone failed — check your network connection and retry, or clone manually."
fi

# ---------------------------------------------------------------------------
# 3. Upstream Jailhouse, reference only (jailhouse-rt is tracked in this repo)
# ---------------------------------------------------------------------------
echo
if [ -d "$PROJECT_DIR/third_party/siemens-jailhouse" ]; then
  echo "==> third_party/siemens-jailhouse/ already present — skipping."
elif [ -f "$PROJECT_DIR/third_party/siemens-jailhouse.zip" ]; then
  echo "==> Unpacking third_party/siemens-jailhouse.zip ..."
  unzip -q "$PROJECT_DIR/third_party/siemens-jailhouse.zip" -d "$PROJECT_DIR/third_party"
else
  echo "!! third_party/siemens-jailhouse.zip not found (optional):"
  echo "   git clone https://github.com/siemens/jailhouse.git third_party/siemens-jailhouse"
fi

# ---------------------------------------------------------------------------
# 4. Results directory structure (the project guide §4.4)
# ---------------------------------------------------------------------------
echo
echo "==> Setting up results/ directory structure..."
for scenario in \
  "scenario1_baseline_idle" \
  "scenario2_spatial_only" \
  "scenario3_cache_coloring" \
  "scenario4_throughput_unixbench"
do
  mkdir -p "$PROJECT_DIR/results/pi4/$scenario"
  mkdir -p "$PROJECT_DIR/results/pi5/$scenario"
done
mkdir -p "$PROJECT_DIR/results/pi4/raw_logs" "$PROJECT_DIR/results/pi5/raw_logs"

[ -f "$PROJECT_DIR/results/README.md" ] || cat > "$PROJECT_DIR/results/README.md" << 'EOF'
# Results directory

Mirrors the thesis's four scenarios (the project guide §3 Phase 4) for both boards,
so Pi 4 vs. Pi 5 numbers land in directly comparable folders:

- scenario1_baseline_idle/          — baseline/idle latency
- scenario2_spatial_only/           — spatial-isolation-only under stress-ng load
- scenario3_cache_coloring/         — spatial isolation + cache coloring active
- scenario4_throughput_unixbench/   — UnixBench system-throughput comparison

Keep raw cyclictest histograms and stress-ng logs in raw_logs/, not just summary
statistics — per the project guide §4.4, the thesis's per-tool WCL table came
from exactly this kind of raw log retention.
EOF

echo
echo "==> Done. Directory layout:"
find "$PROJECT_DIR" -maxdepth 2 -mindepth 1 | sort | sed "s|$PROJECT_DIR|.|"

echo
echo "Next: see the project guide Phase 1 onward (flashing Raspberry Pi OS Lite,"
echo "the mem= carve-out, and the rpi5.c root cell config)."
echo "Status: STATUS.md, open tasks: TODO.md."
