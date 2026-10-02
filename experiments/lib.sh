#!/bin/bash
# Shared functions for the Pi 5 experiment scripts (sourced, runs ON the Pi).
# Settings (override before calling):
#   ROOT_CPUS   CPUs of the root cell used for load        (default 0-2)
#   NLOAD       stressor instances, one per root CPU       (default 3)
#   FIX_FREQ=1  pin all cores to the performance governor (2.4 GHz) for
#               every configuration (the Pi 5 cores share one clock)
set -u
RES=${RES:-$HOME/results}
JH=$HOME/jailhouse-rt
EXP=$HOME/experiments
UB=$HOME/byte-unixbench/UnixBench
ROOT_CPUS=${ROOT_CPUS:-0-2}
NLOAD=${NLOAD:-3}
OUT=

log()  { echo "$(date '+%F %T') $*"; }
mark() { echo "$EPOCHREALTIME $*" >> "$OUT/markers.log"; sync "$OUT/markers.log"; }

# Resume support for single runs <scenario> <load> <rep>: returns 0 (skip)
# if the run finished before, or if it started but never ended - the board
# hung and the watchdog reset it; such runs are marked "hang", not retried.
already_run() {
	local m=$OUT/markers.log
	grep -aq " END $1 $2 $3 " "$m" 2>/dev/null && return 0
	if grep -aqE " START $1 $2 $3\$" "$m" 2>/dev/null; then
		mark END "$1" "$2" "$3" hang
		log "$1 $2 rep $3 hung the board earlier, skipping"
		return 0
	fi
	return 1
}
temp() { cat /sys/class/thermal/thermal_zone0/temp; }
wait_cool() { while [ "$(temp)" -gt 60000 ]; do sleep 5; done; }
check_thermal() {
	if [ -e /run/thermal-abort ]; then
		mark THERMAL "$(tail -1 /run/thermal-abort)"
		log "thermal guard fired: $(tail -1 /run/thermal-abort)"
		sudo rm -f /run/thermal-abort
	fi
	wait_cool
	# re-apply before every run: the kernel resets the governor to
	# ondemand when cell create takes a CPU away from Linux
	[ "${FIX_FREQ:-0}" = 1 ] && fix_freq
}

fix_freq() {
	local p
	for p in /sys/devices/system/cpu/cpufreq/policy*; do
		echo performance | sudo tee "$p/scaling_governor" >/dev/null
	done
}

use_config() {
	OUT=$RES/$1
	mkdir -p "$OUT"
	[ "${FIX_FREQ:-0}" = 1 ] && fix_freq
	local f=/sys/devices/system/cpu/cpu0/cpufreq
	log "=== config $1 (root CPUs $ROOT_CPUS, $NLOAD load instances," \
	    "governor $(cat $f/scaling_governor), $(($(cat $f/scaling_cur_freq) / 1000)) MHz)"
	mark CONFIG "$(cat $f/scaling_governor)" "$(cat $f/scaling_cur_freq)"
}

jh() { sudo "$JH/tools/jailhouse" "$@"; }

# timer interrupt count per root CPU every 5 s, synced so that it survives a
# watchdog reset: shows whether a CPU stopped getting its timer before a hang
start_irqmon() {
	[ -f /tmp/irqmon.pid ] && kill "$(cat /tmp/irqmon.pid)" 2>/dev/null
	(while sleep 5; do
		echo "$EPOCHREALTIME $(grep arch_timer /proc/interrupts | awk '{print $2, $3, $4}')" \
			>> "$OUT/irqmon.log"
		sync "$OUT/irqmon.log"
	done) &
	echo $! > /tmp/irqmon.pid
}

start_logger() {
	sudo pkill -f "jailhouse console -f" 2>/dev/null
	(sudo stdbuf -o0 "$JH/tools/jailhouse" console -f |
		while IFS= read -r l; do printf '%s %s\n' "$EPOCHREALTIME" "$l"; done \
		>> "$OUT/console.log") &
	sleep 1
}

# (re)start the guest cell: <cell config name without .cell> [inmate command line]
# rpi5-linux-* cells boot the PREEMPT_RT Linux guest (linux-guest/, Image in
# ~/linux-guest) running cyclictest in 1 s windows; rpi5-zephyr* cells run the
# Zephyr rt-bench (~/zephyr/rt-bench.bin); all others the bare-metal rt-bench.
start_cell() {
	local cfg=$JH/configs/arm64/$1.cell c
	local args=()
	[ -n "${2:-}" ] && args=(-s "$2" -a 0x1000)
	if [ "$(cat /sys/devices/jailhouse/enabled 2>/dev/null)" != 1 ]; then
		sudo cp "$JH/hypervisor/jailhouse.bin" /lib/firmware/
		lsmod | grep -q '^jailhouse' || sudo insmod "$JH/driver/jailhouse.ko"
		jh enable "$JH/configs/arm64/rpi5.cell" || { log "enable failed"; exit 1; }
	fi
	for c in rt-bench linux-guest zephyr; do
		jh cell list | grep -q " $c " && jh cell destroy "$c"
	done
	case $1 in
	rpi5-linux*)
		(cd "$JH" && sudo ./tools/jailhouse cell linux -d configs/arm64/dts/inmate-rpi5.dtb \
			-c "console=hvc0 earlycon=jailhouse ct_secs=1 ${2:-}" "$cfg" \
			"$HOME/linux-guest/Image" >/dev/null) ||
			{ log "linux guest start failed ($1)"; exit 1; } ;;
	rpi5-zephyr*)
		jh cell create "$cfg" &&
		jh cell load zephyr "$HOME/zephyr/rt-bench.bin" -a 0x30000000 &&
		jh cell start zephyr || { log "zephyr start failed ($1)"; exit 1; } ;;
	*)
		jh cell create "$cfg" &&
		jh cell load rt-bench "$JH/inmates/demos/arm64/rt-bench.bin" "${args[@]}" &&
		jh cell start rt-bench || { log "cell start failed ($1)"; exit 1; } ;;
	esac
	start_logger
	start_irqmon
	[ "${FIX_FREQ:-0}" = 1 ] && fix_freq
	sleep 5
	log "guest cell running ($1 ${2:-}), governor" \
	    "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
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
			already_run "$tag" "$load" "$r" && continue
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

s2_stressors() {	# [repetitions] - 100 stressors x 30 s, as in the thesis
	local s rc r
	for r in $(seq 1 "${1:-1}"); do
		while read -r s; do
			already_run s2 "$s" "$r" && continue
			check_thermal
			mark START s2 "$s" "$r"
			timeout 45 stress-ng --"$s" "$NLOAD" --taskset "$ROOT_CPUS" \
				--timeout 30s >/dev/null 2>>"$OUT/stress.err"; rc=$?
			mark END s2 "$s" "$r" "$rc"
			sleep 2
		done < "$EXP/stressors.txt"
	done
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
