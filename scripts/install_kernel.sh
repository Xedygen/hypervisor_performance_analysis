#!/usr/bin/env bash
# Install the Jailhouse-enabled 6.6 kernel from build/kernel-6.6 onto the Pi 5
# next to the stock kernel, and boot it once via tryboot.
#
# Layout on the Pi: /boot/firmware/jh66/{kernel8.img,*.dtb,overlays/,cmdline.txt}
# tryboot.txt = config.txt + os_prefix=jh66/. If the new kernel hangs, a power
# cycle falls back to the stock kernel. Once it works: ./install_kernel.sh --make-default
set -euo pipefail

PI="${PI:-pi@rpi5.local}"
SSH=(ssh -i "$HOME/.ssh/id_ed25519_rpi5" -o BatchMode=yes "$PI")
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
B="$ROOT/build/kernel-6.6"
STAGE="$ROOT/build/stage-6.6"
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

if [ "${1:-}" = --make-default ]; then
  "${SSH[@]}" 'grep -q "^os_prefix=jh66/" /boot/firmware/config.txt ||
    printf "\n[all]\nos_prefix=jh66/\n" | sudo tee -a /boot/firmware/config.txt >/dev/null'
  echo "jh66 kernel is now the default. Undo: delete the os_prefix line in /boot/firmware/config.txt"
  exit 0
fi

KREL="$(cat "$B/include/config/kernel.release")"
rm -rf "$STAGE" && mkdir -p "$STAGE/jh66/overlays"
make -C "$ROOT/raspberrypi-linux" O="$B" INSTALL_MOD_PATH="$STAGE/mods" INSTALL_MOD_STRIP=1 modules_install >/dev/null
rm -f "$STAGE/mods/lib/modules/$KREL/build" "$STAGE/mods/lib/modules/$KREL/source"
cp "$B/arch/arm64/boot/Image" "$STAGE/jh66/kernel8.img"
cp "$B"/arch/arm64/boot/dts/broadcom/bcm27*.dtb "$STAGE/jh66/"
cp "$B"/arch/arm64/boot/dts/overlays/*.dtb* "$STAGE/jh66/overlays/"
cp "$ROOT/raspberrypi-linux/arch/arm/boot/dts/overlays/README" "$STAGE/jh66/overlays/" 2>/dev/null || true

echo "==> copying $KREL to $PI"
tar -C "$STAGE" -czf - jh66 mods | "${SSH[@]}" "
  set -e
  T=\$(mktemp -d); tar -C \$T -xzf -
  # keep jh66's own cmdline (mem= carve-out etc.) across reinstalls
  sudo cp /boot/firmware/jh66/cmdline.txt \$T/cmdline.txt 2>/dev/null ||
    cp /boot/firmware/cmdline.txt \$T/cmdline.txt
  sudo rm -rf /boot/firmware/jh66 /lib/modules/$KREL
  sudo cp -r \$T/jh66 /boot/firmware/jh66
  sudo cp -r \$T/mods/lib/modules/$KREL /lib/modules/
  sudo depmod $KREL
  sudo cp \$T/cmdline.txt /boot/firmware/jh66/cmdline.txt
  { cat /boot/firmware/config.txt; printf '\n[all]\nos_prefix=jh66/\n'; } | sudo tee /boot/firmware/tryboot.txt >/dev/null
  rm -rf \$T
  echo installed; df -h /boot/firmware | tail -1"

echo "==> tryboot into $KREL (power-cycle the Pi to fall back if it doesn't come back)"
"${SSH[@]}" "sudo reboot '0 tryboot'" || true
