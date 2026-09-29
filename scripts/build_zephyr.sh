#!/usr/bin/env bash
# Build a Zephyr app for the Pi 5 Jailhouse cell (jailhouse-rt/configs/arm64/rpi5-zephyr.c).
# Usage: scripts/build_zephyr.sh [app dir, default zephyr/rt-bench] [extra cmake args, e.g. -DRTB_WS_KB=512]
# Needs third_party/zephyr (git clone --depth 1 https://github.com/zephyrproject-rtos/zephyr)
# and third_party/zephyr-venv (pip install -r third_party/zephyr/scripts/requirements-base.txt).
# Output: build/zephyr-<app>/zephyr/zephyr.bin
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$(realpath "${1:-$ROOT/zephyr/rt-bench}")"
shift || true
export ZEPHYR_BASE="$ROOT/third_party/zephyr"
export ZEPHYR_TOOLCHAIN_VARIANT=cross-compile CROSS_COMPILE=/usr/bin/aarch64-linux-gnu-
. "$ROOT/third_party/zephyr-venv/bin/activate"
OUT="$ROOT/build/zephyr-$(basename "$APP")"
cmake -GNinja -B "$OUT" -S "$APP" -DBOARD=rpi_5 \
	-DEXTRA_DTC_OVERLAY_FILE="$ROOT/zephyr/rpi5-jailhouse.overlay" \
	-DEXTRA_CONF_FILE="$ROOT/zephyr/rpi5-jailhouse.conf" "$@"
ninja -C "$OUT"
echo "on the Pi: jailhouse cell create rpi5-zephyr.cell &&"
echo "  jailhouse cell load zephyr $OUT/zephyr/zephyr.bin -a 0x30000000 && jailhouse cell start zephyr"
