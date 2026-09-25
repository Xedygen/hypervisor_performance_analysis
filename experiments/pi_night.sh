#!/bin/bash
# Unattended run of the thesis scenarios on the Pi 5 (runs ON the Pi, as pi).
# Start from a fresh boot (Jailhouse not enabled):
#   nohup ~/experiments/pi_night.sh ~/results > ~/results/night.log 2>&1 &
# Each configuration writes to <results>/<config>/:
#   console.log  hypervisor console (rt-bench "W" lines), prefixed with epoch time
#   markers.log  "<epoch> START|END <scenario> <load> [rc]" around every run
#   unixbench-*.txt, colorhog.txt, stress.err
# Needs: jailhouse-rt built in ~/jailhouse-rt, thermal-guard service running.
set -u
RES=${1:-$HOME/results}
JH=$HOME/jailhouse-rt
EXP=$HOME/experiments
UB=$HOME/byte-unixbench/UnixBench
OUT=

log()  { echo "$(date '+%F %T') $*"; }
mark() { echo "$EPOCHREALTIME $*" >> "$OUT/markers.log"; }
temp() { cat /sys/class/thermal/thermal_zone0/temp; }
wait_cool() { while [ "$(temp)" -gt 60000 ]; do sleep 5; done; }
check_thermal() {
	if [ -e /run/thermal-abort ]; then
		mark THERMAL "$(tail -1 /run/thermal-abort)"
		log "thermal guard fired: $(tail -1 /run/thermal-abort)"
		sudo rm -f /run/thermal-abort
	fi
	wait_cool
}

use_config() {
	OUT=$RES/$1
	mkdir -p "$OUT"
	log "=== config $1"
}

jh() { sudo "$JH/tools/jailhouse" "$@"; }

start_logger() {
	sudo pkill -f "jailhouse console -f" 2>/dev/null
	(sudo stdbuf -o0 "$JH/tools/jailhouse" console -f |
		while IFS= read -r l; do printf '%s %s\n' "$EPOCHREALTIME" "$l"; done \
		>> "$OUT/console.log") &
	sleep 1
}

# (re)start the rt-bench cell with the given config (plain|col)
start_cell() {
	local cfg=$JH/configs/arm64/rpi5-rtbench.cell
	[ "$1" = col ] && cfg=$JH/configs/arm64/rpi5-rtbench-col.cell
	if [ "$(cat /sys/devices/jailhouse/enabled 2>/dev/null)" != 1 ]; then
		sudo cp "$JH/hypervisor/jailhouse.bin" /lib/firmware/
		lsmod | grep -q '^jailhouse' || sudo insmod "$JH/driver/jailhouse.ko"
		jh enable "$JH/configs/arm64/rpi5.cell" || { log "enable failed"; exit 1; }
	fi
	jh cell list | grep -q rt-bench && jh cell destroy rt-bench
	jh cell create "$cfg" &&
	jh cell load rt-bench "$JH/inmates/demos/arm64/rt-bench.bin" &&
	jh cell start rt-bench || { log "cell start failed ($1)"; exit 1; }
	start_logger
	sleep 5
	log "rt-bench cell running ($1)"
}

s1_idle() {	# <seconds> <repetitions>
	for r in $(seq 1 "$2"); do
		check_thermal
		mark START s1 idle "$r"; sleep "$1"; mark END s1 idle "$r" 0
	done
}

run_load() {	# <load> <seconds>
	case $1 in
	idle)	sleep "$2" ;;
	vm)	stress-ng --vm 3 --vm-bytes 64M --taskset 0-2 --timeout "${2}s" \
			>/dev/null 2>>"$OUT/stress.err" ;;
	pwalk)	for c in 0 1 2; do taskset -c $c "$EXP/pwalk" 64 4096 "$2" >/dev/null & done
		wait ;;
	*)	stress-ng --"$1" 3 --taskset 0-2 --timeout "${2}s" \
			>/dev/null 2>>"$OUT/stress.err" ;;
	esac
}

s3_hw() {	# <repetitions> <seconds>
	for r in $(seq 1 "$1"); do
		for load in idle cache stream memcpy vm pwalk; do
			check_thermal
			mark START s3 "$load" "$r"
			run_load "$load" "$2"; rc=$?
			mark END s3 "$load" "$r" "$rc"
			sleep 2
		done
	done
}

s2_stressors() {	# 100 stressors x 30 s, as in the thesis
	local s rc
	while read -r s; do
		check_thermal
		mark START s2 "$s" 1
		timeout 45 stress-ng --"$s" 3 --taskset 0-2 --timeout 30s \
			>/dev/null 2>>"$OUT/stress.err"; rc=$?
		mark END s2 "$s" 1 "$rc"
		sleep 2
	done < "$EXP/stressors.txt"
}

s4_unixbench() {	# <tag>
	check_thermal
	mark START s4 unixbench 1
	(cd "$UB" && ./Run -c 1 -c 3) > "$OUT/unixbench-$1.txt" 2>&1; rc=$?
	mark END s4 unixbench 1 "$rc"
}

hog_on() {
	sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
	sudo "$EXP/colorhog" 24 31 96 > "$OUT/colorhog.txt" 2>&1 &
	until grep -q holding "$OUT/colorhog.txt" 2>/dev/null; do sleep 2; done
	log "$(cat "$OUT/colorhog.txt")"
}
hog_off() { sudo pkill colorhog; sleep 2; }

mkdir -p "$RES"
log "start, temp $(temp)"

# 1. S4 on plain Linux, no hypervisor. CPU 3 offline so the root cell and the
#    reference run have the same 3 CPUs.
# Skipped when a complete result exists: CPU 3 does not come back online
# after a long offline period on this board (firmware PSCI CPU_ON fails),
# so this step needs a reboot afterwards. Better: boot with maxcpus=3.
use_config bare
if [ "$(grep -c 'Index Score' "$OUT/unixbench-bare.txt" 2>/dev/null)" != 2 ]; then
	echo 0 | sudo tee /sys/devices/system/cpu/cpu3/online >/dev/null
	s4_unixbench bare
	log "bare done; reboot before the Jailhouse part (CPU 3 stays offline)"
	exit 0
fi

# 2-5. Jailhouse, guest without colouring (spatial isolation only)
use_config plain
start_cell plain
s1_idle 300 3
s3_hw 3 60
s2_stressors
s4_unixbench jailhouse

# 6. guest coloured (8/32 L3 colours), root Linux unrestricted (thesis config)
use_config col
start_cell col
s1_idle 300 1
s3_hw 3 60

# 7. guest coloured and root kept out of the guest colours (colorhog)
use_config colhog
start_cell col
hog_on
s1_idle 300 1
s3_hw 3 60
s2_stressors
hog_off

log "all done, temp $(temp)"
touch "$RES/DONE"
