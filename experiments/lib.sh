#!/bin/bash
# Shared functions for the Pi 5 experiment scripts (sourced, runs ON the Pi).
# Settings (override before calling):
#   ROOT_CPUS   CPUs of the root cell used for load        (default 0-2)
#   NLOAD       stressor instances, one per root CPU       (default 3)
set -u
RES=${RES:-$HOME/results}
JH=$HOME/jailhouse-rt
EXP=$HOME/experiments
UB=$HOME/byte-unixbench/UnixBench
ROOT_CPUS=${ROOT_CPUS:-0-2}
NLOAD=${NLOAD:-3}
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
	log "=== config $1 (root CPUs $ROOT_CPUS, $NLOAD load instances)"
}

jh() { sudo "$JH/tools/jailhouse" "$@"; }

start_logger() {
	sudo pkill -f "jailhouse console -f" 2>/dev/null
	(sudo stdbuf -o0 "$JH/tools/jailhouse" console -f |
		while IFS= read -r l; do printf '%s %s\n' "$EPOCHREALTIME" "$l"; done \
		>> "$OUT/console.log") &
	sleep 1
}

# (re)start the rt-bench cell: <cell config name without .cell> [inmate command line]
start_cell() {
	local cfg=$JH/configs/arm64/$1.cell
	local args=()
	[ -n "${2:-}" ] && args=(-s "$2" -a 0x1000)
	if [ "$(cat /sys/devices/jailhouse/enabled 2>/dev/null)" != 1 ]; then
		sudo cp "$JH/hypervisor/jailhouse.bin" /lib/firmware/
		lsmod | grep -q '^jailhouse' || sudo insmod "$JH/driver/jailhouse.ko"
		jh enable "$JH/configs/arm64/rpi5.cell" || { log "enable failed"; exit 1; }
	fi
	jh cell list | grep -q rt-bench && jh cell destroy rt-bench
	jh cell create "$cfg" &&
	jh cell load rt-bench "$JH/inmates/demos/arm64/rt-bench.bin" "${args[@]}" &&
	jh cell start rt-bench || { log "cell start failed ($1)"; exit 1; }
	start_logger
	sleep 5
	log "rt-bench cell running ($1 ${2:-})"
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
	vm)	stress-ng --vm "$NLOAD" --vm-bytes 64M --taskset "$ROOT_CPUS" \
			--timeout "${2}s" >/dev/null 2>>"$OUT/stress.err" ;;
	pwalk)	local pids=() c
		for c in $(seq -s ' ' ${ROOT_CPUS/-/ }); do
			taskset -c "$c" "$EXP/pwalk" 64 4096 "$2" >/dev/null & pids+=($!)
		done
		# only these: a bare "wait" would also wait for the console logger
		wait "${pids[@]}" ;;
	*)	stress-ng --"$1" "$NLOAD" --taskset "$ROOT_CPUS" --timeout "${2}s" \
			>/dev/null 2>>"$OUT/stress.err" ;;
	esac
}

# <scenario tag> <repetitions> <seconds> <load...>
loads_run() {
	local tag=$1 reps=$2 secs=$3 r load rc
	shift 3
	for r in $(seq 1 "$reps"); do
		for load in "$@"; do
			check_thermal
			mark START "$tag" "$load" "$r"
			run_load "$load" "$secs"; rc=$?
			mark END "$tag" "$load" "$r" "$rc"
			sleep 2
		done
	done
}

s3_hw() {	# <repetitions> <seconds>
	loads_run s3 "$1" "$2" idle cache stream memcpy vm pwalk
}

s2_stressors() {	# 100 stressors x 30 s, as in the thesis
	local s rc
	while read -r s; do
		check_thermal
		mark START s2 "$s" 1
		timeout 45 stress-ng --"$s" "$NLOAD" --taskset "$ROOT_CPUS" --timeout 30s \
			>/dev/null 2>>"$OUT/stress.err"; rc=$?
		mark END s2 "$s" 1 "$rc"
		sleep 2
	done < "$EXP/stressors.txt"
}

s4_unixbench() {	# <tag>
	check_thermal
	mark START s4 unixbench 1
	(cd "$UB" && ./Run -c 1 -c "$NLOAD") > "$OUT/unixbench-$1.txt" 2>&1; rc=$?
	mark END s4 unixbench 1 "$rc"
}

# keep root Linux out of guest colours <first> <last>
hog_on() {
	sync; echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
	sudo "$EXP/colorhog" "$1" "$2" 96 > "$OUT/colorhog.txt" 2>&1 &
	until grep -q holding "$OUT/colorhog.txt" 2>/dev/null; do sleep 2; done
	log "$(cat "$OUT/colorhog.txt")"
}
hog_off() { sudo pkill colorhog; sleep 2; }

# run a step once; a restarted script skips steps that already finished
step() {	# <name> <function> [args]
	local done="$OUT/done.$1"
	[ -e "$done" ] && { log "skip $1 (done)"; return; }
	shift
	"$@" && touch "$done"
}
