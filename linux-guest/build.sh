#!/usr/bin/env bash
# Build the PREEMPT_RT Linux guest (kernel Image with a built-in initramfs)
# for the Pi 5 Jailhouse cell configs/arm64/rpi5-linux-demo.c.
# Source: a worktree of raspberrypi-linux (rpi-6.6.y, 6.6.78) with
# patch-6.6.78-rt51 and hvc-jailhouse.patch applied, in third_party/linux-guest
# (created on the first run).
# Userspace (busybox, cyclictest and their libraries) is copied from the Pi.
# Output: build/linux-guest/arch/arm64/boot/Image
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/third_party/linux-guest"
OUT="$ROOT/build/linux-guest"
RFS="$OUT/rootfs"
PI="${PI:-pi@10.42.0.150}"
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

RT=patch-6.6.78-rt51.patch.xz
if [ ! -d "$SRC" ]; then
	# same rpi-6.6.y commit as the root-cell kernel, without its patches
	git -C "$ROOT/raspberrypi-linux" worktree add --detach "$SRC" HEAD
	[ -f "$ROOT/third_party/$RT" ] || curl -sfL -o "$ROOT/third_party/$RT" \
		"https://cdn.kernel.org/pub/linux/kernel/projects/rt/6.6/older/$RT"
	xzcat "$ROOT/third_party/$RT" | patch -d "$SRC" -p1 -s
	patch -d "$SRC" -p1 -s < "$ROOT/linux-guest/hvc-jailhouse.patch"
fi

mkdir -p "$RFS"
BINS="/usr/bin/busybox /usr/bin/cyclictest"
if [ ! -x "$RFS/usr/bin/cyclictest" ]; then
	# the binaries plus every library ldd lists for them (paths as on the Pi)
	ssh -i "$HOME/.ssh/id_ed25519_rpi5" "$PI" "tar -chf - $BINS \$(ldd $BINS |
		grep -o '/[^ ]*\.so[^ ]*' | sort -u) 2>/dev/null" | tar -C "$RFS" -xf -
fi
mkdir -p "$RFS/bin"; ln -sf /usr/bin/busybox "$RFS/bin/busybox"

{
	echo "dir /dev 0755 0 0"
	echo "nod /dev/console 0600 0 0 c 5 1"
	for d in bin proc sys tmp usr usr/bin lib lib/aarch64-linux-gnu; do echo "dir /$d 0755 0 0"; done
	echo "file /init $ROOT/linux-guest/init 0755 0 0"
	echo "slink /bin/busybox /usr/bin/busybox 0777 0 0"
	(cd "$RFS" && find usr/bin lib -type f) | while read -r f; do
		echo "file /$f $RFS/$f 0755 0 0"
	done
} > "$OUT/initramfs.list"

KCONFIG_ALLCONFIG="$ROOT/linux-guest/guest.config" make -C "$SRC" O="$OUT" allnoconfig >/dev/null
"$SRC/scripts/config" --file "$OUT/.config" --set-str INITRAMFS_SOURCE "$OUT/initramfs.list"
make -C "$SRC" O="$OUT" olddefconfig >/dev/null
make -C "$SRC" O="$OUT" -j"$(nproc)" Image
ls -l "$OUT/arch/arm64/boot/Image"
