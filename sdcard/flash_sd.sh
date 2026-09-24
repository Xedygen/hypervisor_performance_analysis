#!/usr/bin/env bash
# Flash Raspberry Pi OS Lite (Trixie, arm64) to an SD card and drop in the
# cloud-init first-boot config from firstboot/.
# Usage: sudo ./flash_sd.sh /dev/sdX
set -euo pipefail

DEV="${1:?usage: sudo $0 /dev/sdX}"
HERE="$(cd "$(dirname "$0")" && pwd)"
IMG="$HERE/2026-09-15-raspios-trixie-arm64-lite.img.xz"
MAX_BYTES=$((64 * 1024 * 1024 * 1024))

[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }
[ -b "$DEV" ] || { echo "$DEV is not a block device"; exit 1; }
[ -f "$IMG" ] || { echo "missing $IMG"; exit 1; }

# Refuse anything that isn't a small removable disk, so a typo can't wipe an NVMe.
name="$(basename "$DEV")"
[ "$(cat /sys/block/$name/removable)" = 1 ] || { echo "$DEV is not removable, refusing"; exit 1; }
size=$(( $(cat /sys/block/$name/size) * 512 ))
[ "$size" -le "$MAX_BYTES" ] || { echo "$DEV is larger than 64G, refusing"; exit 1; }

lsblk -o NAME,SIZE,TRAN,MODEL "$DEV"
read -rp "Erase $DEV and write Pi OS? type YES: " ok
[ "$ok" = YES ] || exit 1

umount "$DEV"?* 2>/dev/null || true
xz -dc "$IMG" | dd of="$DEV" bs=4M conv=fsync status=progress
partprobe "$DEV"; udevadm settle

BOOT="$(mktemp -d)"
mount "${DEV}1" "$BOOT"
# user-data is a template: fill in the password hash and SSH key here so
# neither lives in the repo. The password file is created once and kept local.
PW_FILE="$HERE/firstboot/.pi-password"
[ -f "$PW_FILE" ] || { openssl rand -base64 9 | tr -d '/+=' > "$PW_FILE"; chmod 600 "$PW_FILE"; }
USER_HOME="$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)"
PUBKEY="$(cat "${SSH_PUBKEY:-$USER_HOME/.ssh/id_ed25519_rpi5.pub}")"
HASH="$(openssl passwd -6 "$(cat "$PW_FILE")")"
sed -e "s|__PASSWD_HASH__|$HASH|" -e "s|__SSH_PUBKEY__|$PUBKEY|" \
  "$HERE/firstboot/user-data" > "$BOOT/user-data"
cp "$HERE/firstboot/network-config" "$BOOT/"
cat "$HERE/firstboot/config-append.txt" >> "$BOOT/config.txt"
touch "$BOOT/ssh"
sync
echo "--- written to boot partition:"
ls -l "$BOOT"/{user-data,network-config,ssh,kernel8.img}
tail -5 "$BOOT/config.txt"
umount "$BOOT"; rmdir "$BOOT"
echo "Done. Put the card in the Pi 5, connect Ethernet, power on."
